# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

ActiveRecord::Base.transaction do

  puts "\nCreating season..."
  raise "Existing data" if Season.any?
  season = Season.create!(name: Date.today.year.to_s,
                          points_single_20: 1,
                          points_single_21: 1,
                          points_single_12: 0,
                          points_single_02: 0,
                          points_double_20: 1,
                          points_double_21: 1,
                          points_double_12: 0,
                          points_double_02: 0,
                          play_off_conditions: "Zápasy sa hrajú do konca augusta, potom sa rebríček uzavrie. Na základe rebríčka z konca augusta sú hráči nominovaní do Play Off, ktoré sa odohrá v septembri. V Play Off sa hrajú 3 samostatné turnajové pavúky. Štyria najvyššie postavení hráči označení ako "reg.", tzn. registrovaní hráči hrajú svoj vlastný pavúk registrovaných hráčov. Ostatní hráči, tzn. neregistrovaní hrajú dva pavúky - pavúk A, do ktorého sú nominovaní ôsmi najvyššie postavení neregistrovaní hráči rebríčka a pavúk B, kde sú nominovaní ďalší 16-ti neregistrovaní hráči. To znamená, celkovo 24 neregistrovaných hráčov hrá Play Off. POZOR! Do všetkých pavúkov Play Off sú prioritizovaní tí hráči, ktorí za sezónu odohrali aspoň 10 zápasov počas leta! To znamená, že hráč, ktorý by rebríčkovo nebol nominovaný do Play Off, ale splnil túto podmienku vystrieda najnižšie postaveného nominovaného hráča, ktorý túto podmienku nesplnil.")


  puts "\nCreating places..."
  raise "Existing data" if Place.any?
  ["Mravenisko", "Kúpalisko"].each do |name|
    Place.create!(name:)
  end


  puts "\nCreating tags..."
  raise "Existing data" if Tag.any?
  ["reg."].each do |label|
    Tag.create!(label:)
  end


  puts "\nCreating tournaments..."
  raise "Existing data" if Tournament.any?
  tournaments_to_create = 4
  tournaments_to_create.times.with_index do |i, idx|
    suffix = rand(0..1) == 0 ? "Open" : "Cup"
    date = if idx < (tournaments_to_create - 1)
             ((Date.today - 30.days)..(Date.today - 1.day)).to_a.sample
           else
             date = Date.today + 5.days
           end
    main_info = ""
    rand(3..5).times do
      main_info += "#{Faker::Lorem.word}: "
      main_info += "#{Faker::Lorem.words(number: rand(1..2)).join(' ')}\n"
    end
    side_info = Faker::Lorem.sentences(number: rand(6..10)).join(' ')

    season.tournaments.create!(
      name: "#{Faker::Creature::Animal.name.capitalize} #{suffix}",
      begin_date: date,
      end_date: date + rand(0..1).day,
      main_info: main_info,
      side_info: side_info,
      published_at: Time.now,
      place: (rand(0..2) > 0) ? Place.all.sample : nil
    )
  end


  puts "\nCreating players..."
  raise "Existing data" if Player.any?
  players_data = [
    { name: "Tomáš Radič", email: "tomas.radic@gmail.com", birth_year: 1980, phone_nr: "0905289248" },
    { name: "Michal Bihary" },
    { name: "Branislav Lištiak" },
    { name: "Michal Dovalovský" },
    { name: "Slavo Kutňanský" },
    { name: "Ivan Šlosár" },
    { name: "Ľuboš Hollan" },
    { name: "Marek Bednárik" },
    { name: "Jarik Šípoš" },
    { name: "Tomáš Dobek" },
    { name: "Ľuboš Barborík" },
    { name: "Igor Malinka" },
    { name: "Braňo Milata" },
    { name: "Michal Kollár" },
    { name: "Juro Sulík" },
    { name: "Peter Klačanský" },
    { name: "Tomáš Korytár" },
    { name: "Marek Kúdela" },
    { name: "Rasťo Kováč" },
    { name: "Lucia Machová" },
    { name: "Igor Vestenický" },
    { name: "Ján Čangel" },
    { name: "Ján Arpaš" },
    { name: "Augusta Tobiášová" },
    { name: "Marek Náhlik" },
  ].shuffle

  players_data.each do |pd|
    player = Player.create!(
      name: pd[:name],
      email: pd[:email] || "#{I18n.transliterate(pd[:name]).downcase.gsub(/\s+/, '.')}@total.pink",
      phone_nr: pd[:phone_nr] || Faker::PhoneNumber.cell_phone,
      birth_year: pd[:birth_year] || Date.today.year - rand(20..60),
      password: "rogerf"
    )

    player.confirm
    season.players << player
  end


  puts "\nCreating matches..."
  raise "Existing data" if Match.any?

  # Finished & reviewed matches
  100.times do
    players = Player.all.sample(2)
    match_time = rand(2.weeks).seconds.ago.to_date

    match = Match.new(
      published_at: match_time,
      requested_at: match_time,
      accepted_at: match_time,
      play_date: match_time,
      play_time: Match.play_times.values.sample,
      winner_side: 1,
      finished_at: match_time,
      reviewed_at: match_time,
      competitable: season,
      place: (rand(0..2) > 0) ? Place.all.sample : nil,
      set1_side1_score: 6,
      set1_side2_score: rand(0..4),
      set2_side1_score: 6,
      set2_side2_score: rand(0..4),
      assignments: [
        Assignment.new(side: 1, player: players[0]),
        Assignment.new(side: 2, player: players[1])
      ]
    )

    players_reacted = Player.order("RANDOM()").limit(rand(0..5))
    players_reacted.each do |p|
      match.reactions << Reaction.new(player: p)
    end

    players_commented = Player.order("RANDOM()").limit(rand(0..3))
    players_commented.each do |p|
      comment = Comment.new(commentable: match, player: p,
                            content: Faker::Lorem.sentence(word_count: 16, random_words_to_add: 10),
                            motive: match.comments[rand(0..match.comments.size)])
      match.comments << comment
    end

    match.save!
  end

  # Accepted matches
  players = Player.all.to_a
  3.times do
    player1 = players.delete(players.sample)
    player2 = players.delete(players.sample)
    match_time = rand(2.weeks).seconds.from_now.to_date

    Match.create!(
      published_at: match_time,
      requested_at: match_time,
      accepted_at: Time.now,
      play_date: match_time,
      play_time: Match.play_times.values.sample,
      competitable: season,
      assignments: [
        Assignment.new(side: 1, player: player1),
        Assignment.new(side: 2, player: player2)
      ]
    )
  end

  player1 = players.delete(players.sample)
  player2 = players.delete(players.sample)

  Match.create!(
    requested_at: rand(3.days).seconds.ago.to_datetime,
    accepted_at: Time.now,
    published_at: Time.now,
    competitable: season,
    assignments: [
      Assignment.new(side: 1, player: player1),
      Assignment.new(side: 2, player: player2)
    ]
  )

  # Requested matches
  2.times do
    player1 = players.delete(players.sample)
    player2 = players.delete(players.sample)

    Match.create!(
      requested_at: rand(3.days).seconds.ago.to_datetime,
      published_at: Time.now,
      competitable: season,
      assignments: [
        Assignment.new(side: 1, player: player1),
        Assignment.new(side: 2, player: player2)
      ]
    )
  end

  # Rejected matches
  players = Player.all.to_a
  player1 = players.delete(players.sample)
  player2 = players.delete(players.sample)

  Match.create!(
    requested_at: rand(3.days).seconds.ago.to_datetime,
    rejected_at: Time.now,
    published_at: Time.now,
    competitable: season,
    assignments: [
      Assignment.new(side: 1, player: player1),
      Assignment.new(side: 2, player: player2)
    ]
  )


  puts "\nCreating predictions..."
  raise "Existing data" if Prediction.any?

  Match.all.each do |m|
    used_player_ids = []

    rand(0..8).times do
      player = Player.where.not(id: used_player_ids).sample
      used_player_ids << player.id

      m.predictions.create!(player: player, match: m, side: rand(1..2))
    end
  end


  puts "\nCreating managers..."
  raise "Existing data" if Manager.any?
  [
    "tomas.radic@gmail.com"
  ].each do |email|
    Manager.create!(
      email: email,
      password: "hesielko"
    )
  end


  puts "\nCreating articles..."
  raise "Existing data" if Article.any?
  Article.create!(
    title: "Welcome",
    content: Faker::Lorem.paragraph(sentence_count: 10, supplemental: true, random_sentences_to_add: 6),
    manager: Manager.all.sample,
    season: season,
    published_at: Time.now
  )
end


puts "\nDone."
