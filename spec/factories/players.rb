FactoryBot.define do
  factory :player do
    phone_nr { SecureRandom.hex }
    email { "#{SecureRandom.hex}@#{SecureRandom.hex}.com" }
    password { SecureRandom.hex }
    name { SecureRandom.hex }
    confirmed_at { 1.week.ago }
  end
end
