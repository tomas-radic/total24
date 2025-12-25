class Matches::RejectService < ApplicationService
  def call(match)
    return failure(match.errors.full_messages, value: match) unless match.update(rejected_at: Time.current)

    success(match)
  end
end
