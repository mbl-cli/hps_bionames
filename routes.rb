class HpsBioApp < Sinatra::Base

  get '/css/:filename.css' do
    scss :"sass/#{params[:filename]}"
  end

  get '/' do
    # haml :index
    redirect '/books'
  end

  get '/books' do
    @books = Book.all
    haml :books
  end

  get '/pages' do
    @book = Book.find params[:book_id]
    @pages = Page.where(book_id: params[:book_id])
    @current_page = params[:page_id] ?  
      Page.find(params[:page_id]) : 
      @pages.first
    @current_tab = params[:tab] || 1
    names = PagesNameString.names(@current_page.id)
    offsets = TagAlong::Offsets.new( names,
                                    offset_start: :pos_start,
                                    offset_end: :pos_end,
                                    data_start: :url)
    tg = TagAlong.new(@current_page.content, offsets)
    @tagged_text = tg.tag("<a class=\"nametag\" href=\"%s\">", '</a>')
    haml :pages
  end

end

