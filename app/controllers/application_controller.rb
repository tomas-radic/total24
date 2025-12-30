class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from(ActiveRecord::RecordNotFound) { redirect_to not_found_path }
  rescue_from(Pundit::NotAuthorizedError) { redirect_to root_path }

  def reload
    redirect_back(fallback_location: root_path)
  end


  private

  helper_method :selected_season
  helper_method :latest_open_season

  def selected_season
    @selected_season ||= Season.sorted.first
  end


  def latest_open_season
    @latest_open_season ||= Season.where(ended_at: nil).order(:position).last
  end


  def pundit_user
    current_player
  end


  def redirect_with_message(path, message = 'Údaje boli upravené.', message_type = :notice)
    flash[message_type] = message
    redirect_to path
  end


  def render_with_message(template_path, message = 'Nepodarilo sa upraviť údaje.', message_type = :alert)
    flash.now[message_type] = message

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('toasts', partial: 'shared/toasts') }
      format.html         { render template_path, status: :unprocessable_entity }
    end
  end
end
