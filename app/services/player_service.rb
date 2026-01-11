class PlayerService < ApplicationService
  def set_open_to_play(player, open = true)
    if open
      player.update(open_to_play_since: Time.current, cant_play_since: nil)
    else
      player.update(open_to_play_since: nil)
    end
    success(player)
  end

  def set_cant_play(player, can_play = false)
    if can_play
      player.update(cant_play_since: nil)
    else
      player.update(cant_play_since: Time.current, open_to_play_since: nil)
    end
    success(player)
  end

  def toggle_season_enrollment(player, season)
    enrollment = season.enrollments.find_by(player_id: player.id)

    if enrollment.present?
      canceled_at = enrollment.canceled_at.present? ? nil : Time.current
      enrollment.update!(canceled_at:)
    else
      enrollment = season.enrollments.create!(
        player: player, rules_accepted_at: Time.current, fee_amount_paid: 0, canceled_at: nil)
    end

    success(enrollment)
  end
end
