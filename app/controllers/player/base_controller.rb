class Player::BaseController < ApplicationController

  before_action :authenticate_player!
  before_action :verify_player!


  private

  def verify_player!
    if current_player.anonymized_at.present?
      sign_out current_player
      redirect_to root_path
    end
  end

  def pundit_user
    current_player
  end

end
