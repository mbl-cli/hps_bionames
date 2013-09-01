class HpsBioApp < Sinatra::Base

  get '/css/:filename.css' do
    scss :"sass/#{params[:filename]}"
  end

  get '/' do
    haml :index
  end

  get '/books' do
    @books = Book.all
    haml :books
  end

  get '/pages' do
    @book = Book.find params[:book_id]
    @pages = Page.where(book_id: params[:book_id])
    @current_page = params[:page_id] ?  Page.find(params[:page_id]) : @pages.first
    @current_tab = params[:tab] || 1
    haml :pages
  end

end

