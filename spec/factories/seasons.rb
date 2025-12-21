FactoryBot.define do
  factory :season do
    name { SecureRandom.hex }

    trait :ended do
      ended_at { 1.month.ago }
    end
  end
end
