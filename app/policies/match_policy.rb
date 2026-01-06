class MatchPolicy < ApplicationPolicy

  def create?(season, requested_player)
    requesting_player = user
    return false if requested_player.cant_play_since.present?
    return false if requesting_player.id == requested_player.id
    return false if requesting_player.anonymized? || requested_player.anonymized?

    return false if season.ended?
    return false unless requesting_player.enrolled_to?(season)
    return false unless requested_player.enrolled_to?(season)

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
    return false unless record.published?
    return false if record.season.ended?
    return false if record.requested?

    assigned?(user, record)
  end


  def destroy?
    return false unless record.published?
    return false if record.season.ended?
    return false unless record.requested?

    assigned?(user, record, side: 1)
  end


  def accept?
    return false unless record.published?
    return false if record.season.ended?
    return false unless record.requested?

    assigned?(user, record, side: 2)
  end


  def reject?
    accept?
  end


  def finish_init?
    finish?
  end


  def finish?
    return false unless record.published?
    return false if record.season.ended?
    return false unless record.accepted?
    return false unless assigned?(user, record)

    record.finished_at.blank? || (record.finished_at >= Config.refinish_match_minutes_limit.minutes.ago)
  end


  def cancel?
    return false unless record.published?
    return false if record.season.ended?
    return false unless record.accepted?

    assigned?(user, record)
  end


  def switch_prediction?
    return false unless record.published?
    return false if record.season.ended?
    return false if !record.pending? && !record.accepted?
    return false if record.predictions_disabled_since.present?

    true
  end


  def mark_notifications_read?
    true
  end


  private

  def assigned?(player, match, side: nil)
    assignments = match.assignments
    assignments = assignments.where(side:) if side.present?
    assignments.exists?(player_id: player.id)
  end
end
