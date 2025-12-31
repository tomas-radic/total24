class MatchPolicy < ApplicationPolicy

  def create?(season, requested_player)
    requesting_player = user
    return false if requested_player.cant_play_since.present?
    return false if requesting_player.id == requested_player.id
    return false if season.ended_at.present?
    return false unless requested_player.confirmed?
    return false if requesting_player.anonymized_at.present? || requested_player.anonymized_at.present?
    return false if season.enrollments.active.find { |e| e.player_id == requesting_player.id }.blank?
    return false if season.enrollments.active.find { |e| e.player_id == requested_player.id }.blank?

    requested_player_pending_matches = requested_player.matches.in_season(season).published.pending
    requesting_player_pending_matches = requesting_player.matches.in_season(season).published.pending
    return false if (requested_player_pending_matches.ids & requesting_player_pending_matches.ids).present?

    if season.max_pending_matches > 0
      return false if requesting_player_pending_matches.size >= season.max_pending_matches
      return false if requested_player_pending_matches.size >= season.max_pending_matches
    end

    if season.max_matches_with_opponent > 0
      requested_player_completed_matches = requested_player.matches.in_season(season).published.reviewed
      requesting_player_completed_matches = requesting_player.matches.in_season(season).published.reviewed

      return false if (requested_player_completed_matches.ids & requesting_player_completed_matches.ids).length >= season.max_matches_with_opponent
    end

    true
  end


  def edit?
    update?
  end


  def update?
    return false if season_ended?(record)
    return false unless record.accepted_at.present?

    record.assignments.find { |a| a.player_id == user.id }
  end


  def destroy?
    return false if season_ended?(record)
    return false if record.accepted? || record.rejected? || record.reviewed?

    record.assignments.where(side: 1)
          .find { |a| a.player_id == user.id }
  end


  def accept?
    return false if season_ended?(record)
    return false if record.reviewed?
    return false if record.canceled?

    record.assignments.where(side: 2)
          .find { |a| a.player_id == user.id }
  end


  def reject?
    accept?
  end


  def finish_init?
    finish?
  end


  def finish?
    if user.is_a?(Player)
      return false if season_ended?(record)
      return false unless update?
      return false if record.canceled?
      return false if record.rejected?
      return false unless record.accepted?

      record.finished_at.blank? || (record.finished_at >= Config.refinish_match_minutes_limit.minutes.ago)
    elsif user.is_a?(Manager)
      # TODO
      false
    else
      false
    end
    # update? && !record.rejected? && !record.reviewed?
  end


  def cancel?
    return false unless record.assignments.find { |a| a.player_id == user.id }
    return false if record.canceled?
    return false if record.rejected?
    return false if record.finished?
    true
  end


  def switch_prediction?
    return false unless record.published?
    return false if record.finished?
    return false if record.canceled?
    return false if record.predictions_disabled_since.present?

    true
  end


  def mark_notifications_read?
    true
  end


  private

  def player_enrolled?(player, match)
    player.enrollments.active.where(season_id: match.season&.id).exists?
  end


  def season_ended?(record)
    record.season&.ended_at.present?
  end

end
