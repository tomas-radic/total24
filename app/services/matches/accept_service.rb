class Matches::AcceptService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    errors = []

    ActiveRecord::Base.transaction do
      unless match.update(accepted_at: Time.current)
        errors += match.errors.full_messages
        raise ActiveRecord::Rollback
      end

      match.players.update_all(open_to_play_since: nil)
    end

    return failure(errors, value: match) if errors.any?



    success(match)
  rescue ActiveRecord::Rollback
    failure(errors, value: match)
  end
end
