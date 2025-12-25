class Matches::RejectService < ApplicationService
  def call(match)
    if match.update!(rejected_at: Time.current)
      success(match)
    else
      failure(match.errors.full_messages, value: match)
    end
  end
end
