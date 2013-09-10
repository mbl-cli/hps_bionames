class Book < ActiveRecord::Base
  has_many :pages

  def names
    @names ||= CanonicalForm.find_by_sql("
      select cf.*, count(*) as num
      from canonical_forms cf 
        join resolved_name_strings rns 
          on rns.canonical_form_id = cf.id 
        join name_strings ns 
          on ns.id = rns.name_string_id 
        join pages_name_strings pns 
          on pns.name_string_id = ns.id 
        join pages pg
          on pg.id = pns.page_id
      where pg.book_id = %s
      group by cf.id
      order by num desc" % self.id)
  end

end

class NameString < ActiveRecord::Base
  belongs_to :resolved_name_string
end

class CanonicalForm < ActiveRecord::Base
  has_many :resolved_name_strings
end

class Page < ActiveRecord::Base
  belongs_to :book
  has_many :pages_name_strings
  has_many :name_strings, through: :pages_name_strings

  def img_name
    page_name.gsub(/\.tiff.*/, '.jpg').gsub(/\s/, '-')
  end
  
  def names
    @names ||= get_names
  end

  private

  def get_names
    CanonicalForm.find_by_sql("
      select cf.*, count(*) as num
      from canonical_forms cf 
        join resolved_name_strings rns 
          on rns.canonical_form_id = cf.id 
        join name_strings ns 
          on ns.id = rns.name_string_id 
        join pages_name_strings pns 
          on pns.name_string_id = ns.id 
      where pns.page_id = %s
      group by cf.id
      order by cf.name" % self.id)
  end

end

class EolPage < ActiveRecord::Base
  belongs_to :resolved_name_string
end

class PagesNameString < ActiveRecord::Base
  belongs_to :page
  belongs_to :name_string

  def self.names(page_id)
    res = {}
    db_res = self.connection.select("
      select pns.id, pns.pos_start, pns.pos_end, rns.id as resolved_id, ep.url 
      from pages_name_strings pns 
      join resolved_name_strings rns 
        on pns.name_string_id = rns.name_string_id 
      left outer join eol_pages ep 
        on ep.resolved_name_string_id = rns.id 
      where page_id = %s" % page_id.to_i)
    db_res.each do |r|
      next if (res[r['id']] && res[r['id']][:url])
      if res[r['id']] && r['url']
        res[r['id']][:url] = r['url']
      else
        res[r['id']] = { pos_start: r['pos_start'],
                         pos_end: r['pos_end'],
                         url: r['url'] }
      end
    end
    res.values
  end
end

class ResolvedNameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_strings
  has_many :eol_pages
  has_many :pages_name_strings
  has_many :pages, through: :pages_name_strings
end
