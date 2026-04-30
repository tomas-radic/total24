# frozen_string_literal: true

class MatchComponent < ViewComponent::Base
  def initialize(match:, player:)
    @match = match
    @player = player
  end
end
