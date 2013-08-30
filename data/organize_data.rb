#!/usr/bin/env ruby

require 'mysql2'
require 'json'



class Organizer

  def initialize
    @db = Mysql2::Client.new(host: 'localhost', username: 'root',
                             database: 'embryology')
  end

  def organize
    cleanup
    find_books
    import_names
  end

  def cleanup
    ['books', 'name_strings', 'pages', 
     'pages_name_strings', 'resolved_name_strings', 
     'eol_pages', 'canonical_forms'].each do |t|
      @db.query("truncate table %s" % t)
    end
  end

  def find_books
    Dir.entries(File.dirname(__FILE__)).each do |e|
      if File.directory?(e) && e.match(/^Embryology/)
        @db.query("insert into books (title) values ('%s')" % e)
        id = @db.query("select last_insert_id() as id").first['id']
      end
    end
    books
  end

  def books
    @books = @db.query("select title, id from books").inject({}) do |res,r|
      res[r['title']] = r['id']
      res
    end
  end

  def import_names
    @books.each do |title, id|
      Dir.entries(title).each do |e|
        if e.match /json$/
          file = File.join(title, e)
          data = JSON.parse(open(file).read, symbolize_names: true)
          page_id = add_page(id, e[0..-5], data)
          data[:names].map do |n|
            add_name_strings(n)
          end
          unless data[:names].empty?
            resolve_names(data)
            add_page_names(page_id, data[:names])
          end
        end
      end
    end
  end

  private

  def add_page_names(page_id, names)
    names.each do |n|
      name = @db.escape(n[:scientificName])
      verbatim_name = @db.escape(n[:verbatim])
      pos_start = n[:offsetStart]
      pos_end = n[:offsetEnd]
      name_string_id = @db.query("select id
                                 from name_strings where name = '%s'" %
                                 name).first['id']
      data = [page_id, name_string_id, verbatim_name,
              pos_start, pos_end].map { |e| quote(e) }
      @db.query("insert into pages_name_strings
                 (page_id, name_string_id, verbatim_name,
                 pos_start, pos_end)
                 values
                 (%s, %s, %s, %s, %s)" % data)
    end
  end

  def add_page(book_id, page, data)
    @db.query("insert into pages
              (book_id, page_name, content)
              values
              (%s, %s, %s)" %
              [book_id, page, data[:content]].map { |e| quote(e) })
    @db.query("select last_insert_id() as id").first['id']
  end

  def resolve_names(data)
    resolved, unresolved = data[:resolved_names].partition do |n|
      n[:results] && n[:results].first
    end
    update_unresolved(unresolved)
    update_resolved(resolved)
  end

  def update_unresolved(unresolved)
    unresolved.each do |n|
      name = @db.escape(n[:supplied_name_string])
      @db.query("update name_strings set resolved = 0 where name = '%s'
                and resolved is null" % name)
    end
  end

  def update_resolved(resolved)
    return if resolved.empty?
    names = resolved.map { |n| @db.escape(n[:supplied_name_string]) }
    db_names = "'%s'" % names.join("','")
    new_names = @db.query("select id, name from name_strings where name in (%s)
                          and resolved is null" % db_names)
    if new_names.first
      ids = new_names.map { |n| n['id'] }.join(',')
      names = new_names.inject({}) do |res, n|
        res[n['name']] = n['id']
        res
      end
      @db.query("update name_strings set resolved = 1 where id in (%s)" % ids)
      resolved.each do |n|
        name = n[:supplied_name_string]
        if name_string_id = names[name]
          save_resolved_data(n, name_string_id)
        end
      end
    end
  end

  def save_resolved_data(n, name_string_id)
    data = prepare_resolved_data(n, name_string_id)
    @db.query("insert into resolved_name_strings
              (name_string_id, name, current_name,
               classification, ranks, canonical_form_id,
               in_curated_sources, data_sources_num,
               match_type, data_source_id, data_source) values
               (%s, %s, %s,
                %s, %s, %s,
                %s, %s, %s, %s, %s)" % data)
    id = @db.query("select last_insert_id() as id").first['id']
    eol_data = prepare_eol_data(id, n[:preferred_results])
    eol_data.each do |e|
      @db.query("insert into eol_pages
              (resolved_name_string_id, name, url)
              values
              (%s, %s, %s)" % e)
    end
  end

  def prepare_eol_data(resolved_name_string_id, eol_results)
    eol_data = []
    eol_results.each do |e|
      name = e[:name_string]
      url = e[:url]
      eol_data << [resolved_name_string_id, name, url].map { |e| quote(e) }
    end
    eol_data
  end

  def prepare_resolved_data(n, name_string_id)
    r = n[:results].first
    name = r[:name_string]
    current_name = r[:current_name]
    data_source_id = r[:data_source_id]
    data_source = r[:data_source_title]
    classification = r[:classification_path]
    ranks = r[:classification_path_ranks]
    canonical_form_id = get_canonical_form_id(r[:canonical_form])
    in_curated_sources = n[:in_curated_sources] ? 1 : 0
    data_sources_num = n[:data_sources_number]
    match_type = r[:match_type]
    [name_string_id, name, current_name, classification, ranks,
     canonical_form_id, in_curated_sources, data_sources_num,
     match_type, data_source_id, data_source].map { |n| quote(n) }
  end

  def get_canonical_form_id(name)
    name = @db.escape(name)
    id = @db.query("select id from canonical_forms where name = '%s'" %
                   name).first
    if id
      id['id']
    else
      @db.query("insert into canonical_forms (name) values
                ('%s')" % name)
      @db.query("select last_insert_id() as id").first['id']
    end
  end

  def quote(obj)
    return 'null' unless obj
    return obj if obj.is_a? Fixnum
    "'%s'" % @db.escape(obj)
  end

  def add_name_strings(n)
    name = @db.escape(n[:identifiedName])
    sci_name = @db.escape(n[:scientificName])
    name_exists = @db.query("select 1
                             from name_strings
                             where name = '%s'" % sci_name).first
    if name_exists
      @db.query("update name_strings set expanded_abbr = 0
                where name = '%s'" % name) if name == sci_name
    else
      expanded = (name == sci_name) ? 0 : 1
      @db.query("insert into name_strings (name, expanded_abbr)
                values ('%s', %s)" %
              [sci_name, expanded])
    end
            # [n[:verbatim], n[:scientificName], n[:identifiedName]]
  end

end


o = Organizer.new
o.organize
