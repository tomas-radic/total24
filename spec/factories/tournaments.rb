FactoryBot.define do
  factory :tournament do
    association :season

    name { Faker::Lorem.word }
    main_info { Faker::Lorem.word }
    color_base { Tournament.color_bases["base_green"] }
    published_at { Time.current }
    begin_date { Date.today }
    end_date { Date.today }
  end
end
