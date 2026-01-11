class PagesController < ApplicationController

  def about
    @last_season = Season.sorted.first
  end


  # TODO: Not found page (404) to be served as static page later. Currently lazy to resolve it's styling, sorry.
  def not_found; end


  def help; end

  def reservations; end
  
  def sitemap
    @urls = [
      root_url,
      today_url,
      rankings_url,
      play_off_url,
      about_url,
      reservations_url,
      help_url,
      tournaments_url,
      matches_url,
      articles_url
    ]
    
    # Add individual resources if needed, but for now top-level is a good start.
    # We can add @articles = Article.published, etc if we want more depth.
    @articles = Article.published
    @players = Player.all
    @tournaments = Tournament.all

    respond_to do |format|
      format.xml
    end
  end

end
