FactoryBot.define do
  factory :player_tag do
    association :player
    association :tag
  end
end
