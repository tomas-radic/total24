class Manager::ArticlesController < Manager::BaseController

  def index
    @articles = managed_season&.articles&.order(created_at: :desc)
  end


  def new
    @heading = "Nový článok"
    @article = managed_season.articles.new
  end


  def create
    @article = managed_season.articles.new(
      { manager_id: current_manager.id }.merge(whitelisted_params))

    if @article.save
      respond_to do |format|
        format.html { redirect_with_message manager_articles_path }
        format.turbo_stream { redirect_with_message manager_articles_path }
      end
    else
      @heading = @article.title.presence || "Nový článok"
      render :new, status: :unprocessable_entity
      # render_with_message :new
    end
  end


  def edit
    @article = managed_season.articles.find(params[:id])
    @heading = @article.title
  end


  def update
    @article = managed_season.articles.find(params[:id])

    if @article.update(whitelisted_params)
      respond_to do |format|
        format.html { redirect_with_message manager_articles_path }
        format.turbo_stream { redirect_with_message manager_articles_path }
      end
    else
      @heading = params[:heading]
      render :edit, status: :unprocessable_entity
      # render_with_message :edit
    end
  end


  def destroy
    @article = managed_season.articles.find(params[:id])

    if @article.destroy
      redirect_with_message manager_articles_path
    else
      @heading = @article.title
      render_with_message :edit
    end
  end


  private

  def whitelisted_params
    params.require(:article).permit(:title, :content, :link, :promote_until, :color_base,
                                    :published_at, :comments_disabled_since)
  end

end
