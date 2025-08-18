# frozen_string_literal: true

class Player::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    player = Player.find_by(email: params[:player][:email])

    if player&.anonymized_at.present?
      flash[:alert] = "Tento email už nie je platný."
      redirect_to new_player_session_path
    else
      super
    end

  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
