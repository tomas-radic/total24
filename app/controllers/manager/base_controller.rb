class Manager::BaseController < ApplicationController

  layout "manager"

  before_action :authenticate_manager!

  helper_method :managed_season

  def managed_season
    @managed_season = Season.sorted.first
  end

  def pundit_user
    current_manager
  end
end
