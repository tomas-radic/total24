class Player::PlayersController < Player::BaseController

  def toggle_open_to_play
    is_currently_open = current_player.open_to_play_since.present?

    player_service.set_open_to_play(current_player, !is_currently_open)

    broadcast_players_open_to_play

    render partial: "shared/navbar"
  end


  def toggle_cant_play
    is_currently_cant_play = current_player.cant_play_since.present?

    player_service.set_cant_play(current_player, is_currently_cant_play)

    broadcast_players_open_to_play

    render partial: "shared/navbar"
  end


  def anonymize
    if params[:confirmation_email] == current_player.email
      current_player.anonymize!
      sign_out current_player
      redirect_with_message root_path, 'Registrácia bola zrušená.'
    else
      redirect_with_message edit_player_registration_path, 'Registráciu sa nepodarilo zrušiť.', :alert
    end
  end

  private

  def player_service
    @player_service ||= PlayerService.new
  end
end
