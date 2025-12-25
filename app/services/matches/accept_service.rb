class Matches::AcceptService < ApplicationService
  def call(match)
    errors = []

    ActiveRecord::Base.transaction do
      unless match.update!(accepted_at: Time.current)
        errors += match.errors.full_messages
        raise ActiveRecord::Rollback
      end

      match.players.each do |p|
        p.update!(open_to_play_since: nil)
      end
    end

    if errors.any?
      failure(errors, value: match) if errors.any?
    else
      success(match)
    end
  rescue ActiveRecord::Rollback
    failure(errors, value: match)
  end
end
