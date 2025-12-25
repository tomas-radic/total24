class Matches::CancelService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    return failure(match.errors.full_messages, value: match) unless match.update(canceled_at: Time.current, canceled_by: @current_player)



    success(match)
  end
end
