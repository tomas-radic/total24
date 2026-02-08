class Player::EnrollmentsController < Player::BaseController
  def create
    enrollment = current_player.enrollments.build(season: selected_season)
    enrollment.rules_accepted_at = Time.current if params[:agreement] == "1"

    if enrollment.save
      flash[:notice] = "Pravidlá boli úspešne odsúhlasené."
    else
      flash[:notice] = "Nastala chyba, nepodarilo sa odsúhlasiť pravidlá."
    end

    redirect_back(fallback_location: root_path)
  end
end
