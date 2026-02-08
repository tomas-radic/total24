FactoryBot.define do
  factory :player do
    phone_nr { SecureRandom.hex }
    email { "#{SecureRandom.hex}@#{SecureRandom.hex}.com" }
    password { SecureRandom.hex }
    name { SecureRandom.hex }
    confirmed_at { 1.week.ago }

    transient do
      seasons { [] }
    end

    after(:create) do |player, evaluator|
      evaluator.seasons.each do |season|
        create(:enrollment, player: player, season: season)
      end
    end
  end
end
