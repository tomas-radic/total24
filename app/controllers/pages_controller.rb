class PagesController < ApplicationController

  def about
    @last_season = Season.sorted.first
  end


  def not_found; end


  def help; end

  def reservations; end

end
