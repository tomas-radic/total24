class Manager::SeasonsController < Manager::BaseController

  def new
    @season = Season.new
  end


  def create
    @season = Season.new(whitelisted_params)

    if @season.save
      flash[:notice] = 'Údaje boli upravené.'
      redirect_to manager_pages_dashboard_path
    else
      flash.now[:alert] = 'Nepodarilo sa upraviť údaje.'

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update('toasts', partial: 'shared/toasts') }
        format.html         { render "manager/seasons/new", status: :unprocessable_entity }
      end
    end
  end


  def edit

  end


  def update
    if @managed_season.update(whitelisted_params)
      redirect_to manager_pages_dashboard_path
    else
      render "manager/seasons/edit", status: :unprocessable_entity
    end
  end


  # def destroy
  #
  # end


  private

  def whitelisted_params
    params.require(:season).permit(
      :name, :play_off_size,
      :points_single_20, :points_single_21, :points_single_02, :points_single_12,
      :points_double_20, :points_double_21, :points_double_02, :points_double_12,
      :ended_at)
  end
end
