class RankingsController < ApplicationController

  def index; end

  def play_off
    @play_offs = selected_season.play_offs if selected_season
  end

end
