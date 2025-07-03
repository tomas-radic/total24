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

    if ENV["MAX_PENDING_MATCHES"].present?
      return false if requesting_player_pending_matches.size >= ENV["MAX_PENDING_MATCHES"].to_i
      return false if requested_player_pending_matches.size >= ENV["MAX_PENDING_MATCHES"].to_i
    end

    if ENV['MAX_MATCHES_WITH_OPPONENT'].present?
      requested_player_completed_matches = requested_player.matches.in_season(season).published.reviewed
      requesting_player_completed_matches = requesting_player.matches.in_season(season).published.reviewed

      return false if (requested_player_completed_matches.ids & requesting_player_completed_matches.ids).length >= ENV['MAX_MATCHES_WITH_OPPONENT'].to_i
    end

    true
  end


  def edit?
    update?
  end


  def update?
    return false if season_ended?(record)
    return false unless record.ranking_counted?
    return false unless record.accepted_at.present?

    record.assignments.find { |a| a.player_id == user.id }
  end


  def destroy?
    return false if season_ended?(record)
    return false unless record.ranking_counted?
    return false if record.accepted? || record.rejected? || record.reviewed?

    record.assignments.where(side: 1)
          .find { |a| a.player_id == user.id }
  end


  def accept?
    return false if season_ended?(record)
    return false unless record.ranking_counted?
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
      if record.competitable.is_a?(Season)
        return false if season_ended?(record)
        return false unless update?
        return false if record.canceled?
        return false if record.rejected?
        return false unless record.accepted?

        record.finished_at.blank? ||
          (record.finished_at >= Rails.configuration.minutes_refinish_match.minutes.ago)
      else
        return false
      end


    elsif user.is_a?(Manager)
      # TODO
      false
    else
      false
    end
    # update? && !record.rejected? && !record.reviewed?
  end


  def cancel?
    if record.competitable.is_a?(Season)
      return false unless record.assignments.find { |a| a.player_id == user.id }
      return false if record.canceled?
      return false if record.finished?
      return false if record.rejected?
      return false if record.requested?
      true
    else
      false
    end
  end


  def switch_prediction?
    return false unless record.published?
    return false if record.finished?
    return false if record.canceled?
    return false if record.predictions_disabled_since.present?

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
