class Manager::PlayersController < Manager::BaseController

  before_action :load_player, only: [:edit, :update, :toggle_confirmed]


  def edit
  end


  def update
  end


  def toggle_confirmed
    if @player.confirmed?
      @player.update(confirmed_at: nil)
    else
      @player.confirm
    end

    redirect_back fallback_location: manager_pages_dashboard_path
  end


  private

  def load_player
    @player = Player.find params[:id]
  end

end
