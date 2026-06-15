class TournamentPresenter
  def initialize(tournament)
    @tournament = tournament
  end

  def date
    result = ""
    return result unless @tournament.begin_date.present?

    result = ApplicationController.helpers.app_date @tournament.begin_date
    return result unless @tournament.end_date.present?

    if @tournament.end_date > @tournament.begin_date
      result += " - #{ApplicationController.helpers.app_date @tournament.end_date}"
    end

    result
  end
end
