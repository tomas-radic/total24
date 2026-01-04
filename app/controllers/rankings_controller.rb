class RankingsController < ApplicationController

  def index
    @ranking = SeasonStandings.new(selected_season).ranking if selected_season
  end

  def play_off
    @play_offs = SeasonStandings.new(selected_season).play_offs if selected_season
  end

end
