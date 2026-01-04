class Manager::EnrollmentsController < Manager::BaseController

  def toggle
    player = Player.find params[:player_id]
    PlayerService.new.toggle_season_enrollment(player, managed_season)

    redirect_back fallback_location: manager_pages_dashboard_path
  end
end
