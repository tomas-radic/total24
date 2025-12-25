class Matches::UpdateService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match, params)
    return failure(match.errors.full_messages, value: match) unless match.update(params)
    success(match)
  end
end
