class HpsBio
  class PageText
    def initialize(text)
      @text = text
      @open_tag = '<span class="name_string">'
      @close_tag = '</span>'
    end

    def mark(names, opts)
      offset = 0
      @open_tag = opts[:open_tag] if opts[:open_tag]
      @close_tag = opts[:close_tag] if opts[:close_tag]
      @mark_text = ''
      names.each do |n|
        @mark_text << @text[n.offset_start + offset] 
      end
    end
  end
end
