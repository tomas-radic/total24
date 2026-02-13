class Manager::EnrollmentsController < Manager::BaseController

  def create
    @enrollment = managed_season.enrollments.new(enrollment_params)
    @enrollment.rules_accepted_at = Time.current
    @enrollment.save

    redirect_back fallback_location: manager_pages_dashboard_path
  end

  def update
    @enrollment = managed_season.enrollments.find(params[:id])
    @enrollment.update(enrollment_params)

    redirect_back fallback_location: manager_pages_dashboard_path
  end

  private

  def enrollment_params
    params.require(:enrollment).permit(:player_id, :canceled_at, :fee_amount_paid)
  end
end
