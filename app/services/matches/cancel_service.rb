class Matches::CancelService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    if match.update(canceled_at: Time.current, canceled_by: @current_player)
      success(match)
    else
      failure(match.errors.full_messages, value: match)
    end
  end
end
