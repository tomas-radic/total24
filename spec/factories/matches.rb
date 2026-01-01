FactoryBot.define do
  factory :match do
    association :season

    published_at { Time.current }

    trait :accepted do
      accepted_at { Time.current }
      rejected_at { nil }
      finished_at { nil }
      reviewed_at { nil }
    end

    trait :rejected do
      accepted_at { nil }
      rejected_at { Time.current }
      finished_at { nil }
      reviewed_at { nil }
    end

    trait :finished do
      accepted_at { Time.current }
      rejected_at { nil }
      finished_at { Time.current }
      reviewed_at { nil }
      winner_side { 1 }
      set1_side1_score { 6 }
      set1_side2_score { 4 }
    end

    trait :reviewed do
      accepted_at { Time.current }
      rejected_at { nil }
      finished_at { Time.current }
      reviewed_at { Time.current }
      winner_side { 1 }
      set1_side1_score { 6 }
      set1_side2_score { 4 }
      set2_side1_score { 2 }
      set2_side2_score { 6 }
      set3_side1_score { 6 }
      set3_side2_score { 3 }
    end
  end
end
