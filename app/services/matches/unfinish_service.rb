class Matches::UnfinishService < ApplicationService
  def call(match)
    ActiveRecord::Base.transaction do
      match.update!(finished_at: nil,
                    reviewed_at: nil,
                    winner_side: nil,
                    set1_side1_score: nil,
                    set1_side2_score: nil,
                    set2_side1_score: nil,
                    set2_side2_score: nil,
                    set3_side1_score: nil,
                    set3_side2_score: nil)

      match.assignments.each do |a|
        a.update!(is_retired: false)
      end
    end

    success(match)
  end
end
