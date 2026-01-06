FactoryBot.define do
  factory :season do
    name { SecureRandom.hex }
    performance_play_off_size { 8 }
    play_off_min_matches_count { 3 }
    regular_a_play_off_size { 8 }
    regular_b_play_off_size { 8 }

    trait :ended do
      ended_at { 1.month.ago }
    end
  end
end
