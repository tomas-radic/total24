class Manager::SeasonsController < Manager::BaseController

  def new
    @season = Season.new
  end


  def create
    @season = Season.new(whitelisted_params)

    if @season.save
      redirect_with_message manager_pages_dashboard_path
    else
      render_with_message 'manager/seasons/new'
    end
  end


  def edit

  end


  def update
    if managed_season.update(whitelisted_params)
      redirect_to manager_pages_dashboard_path
    else
      render "manager/seasons/edit", status: :unprocessable_entity
    end
  end


  # def destroy
  #
  # end


  def open_new
    if managed_season.present?
      @season = managed_season.dup
      @season.ended_at = nil
      @season.position = nil
    else
      @season = Season.new
    end

    @season.name = Faker::Music.unique.instrument

    if @season.save
      redirect_with_message manager_pages_dashboard_path, "Nová sezóna bola otvorená."
    else
      redirect_with_message manager_pages_dashboard_path, "Nepodarilo sa otvoriť novú sezónu.", :alert
    end
  end


  private

  def whitelisted_params
    params.require(:season).permit(
      :name,
      :ended_at,
      :performance_play_off_size, :regular_a_play_off_size, :regular_b_play_off_size,
      :play_off_conditions, :play_off_min_matches_count,
      :max_pending_matches, :max_matches_with_opponent)
  end
end
