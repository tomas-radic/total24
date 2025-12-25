class Matches::SwitchPredictionService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match, side)
    prediction = match.predictions.find_by(player: @current_player)

    if prediction.present?
      if side.to_i == prediction.side
        prediction.destroy!
      else
        prediction.update!(side: side)
      end
    else
      match.predictions.create!(player: @current_player, side: side)
    end

    success(match.reload)
  end
end
