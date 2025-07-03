class Manager::BaseController < ApplicationController

  layout "manager"

  before_action :authenticate_manager!
  before_action :set_managed_season


  def set_managed_season
    @managed_season = Season.sorted.where(ended_at: nil).first
    @managed_season ||= Season.sorted.first
  end


  def ensure_managed_season
    if @managed_season.blank?
      redirect_to manager_pages_dashboard_path and return
    end
  end


  def pundit_user
    current_manager
  end

end
