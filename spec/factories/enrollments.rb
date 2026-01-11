FactoryBot.define do
  factory :enrollment do
    association :player
    association :season

    trait :active do
      rules_accepted_at { Time.current }
      fee_amount_paid { 30 }
    end
  end
end
