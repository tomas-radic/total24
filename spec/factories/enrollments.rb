FactoryBot.define do
  factory :enrollment do
    association :player
    association :season
    rules_accepted_at { Time.current }

    trait :active do
      fee_amount_paid { 30 }
    end
  end
end
