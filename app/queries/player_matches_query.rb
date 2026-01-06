class PlayerMatchesQuery < ApplicationQuery
  def initialize(player, relation: Season.sorted.first&.matches)
    @player = player
    @relation = relation || Match.none
  end

  def call
    @relation.joins(:assignments)
             .where(assignments: { player_id: @player.id }).distinct
  end
end
