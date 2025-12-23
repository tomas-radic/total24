class Matches::ToggleReactionService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    reaction = Reaction.find_by(reactionable: match, player: @current_player)

    if reaction.present?
      reaction.destroy!
    else
      Reaction.create!(reactionable: match, player: @current_player)
    end

    success(match.reload)
  end
end
