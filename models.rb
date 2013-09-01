class Book < ActiveRecord::Base
  has_many :pages

  def names
    @names ||= CanonicalForm.find_by_sql("
      select distinct cf.* 
      from canonical_forms cf 
        join resolved_name_strings rns 
          on rns.canonical_form_id = cf.id 
        join name_strings ns 
          on ns.id = rns.name_string_id 
        join pages_name_strings pns 
          on pns.name_string_id = ns.id 
        join pages pg 
          on pg.id = pns.page_id 
        join books b 
          on b.id = pg.book_id 
      where book_id = %s 
      order by cf.name" % self.id)
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
end

class ResolvedNameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_strings
  has_many :eol_pages
  has_many :pages_name_strings
  has_many :pages, through: :pages_name_strings
end
