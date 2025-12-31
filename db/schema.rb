# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_31_090253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "color_base", null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "comments_disabled_since"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "link"
    t.uuid "manager_id", null: false
    t.date "promote_until"
    t.datetime "published_at"
    t.integer "reactions_count", default: 0, null: false
    t.uuid "season_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_articles_on_manager_id"
    t.index ["season_id"], name: "index_articles_on_season_id"
  end

  create_table "assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_retired", default: false, null: false
    t.uuid "match_id", null: false
    t.uuid "player_id", null: false
    t.integer "side", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_assignments_on_match_id"
    t.index ["player_id"], name: "index_assignments_on_player_id"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "commentable_id", null: false
    t.string "commentable_type", null: false
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.uuid "motive_id"
    t.uuid "player_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["motive_id"], name: "index_comments_on_motive_id"
    t.index ["player_id"], name: "index_comments_on_player_id"
  end

  create_table "enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.uuid "player_id", null: false
    t.uuid "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_enrollments_on_player_id"
    t.index ["season_id"], name: "index_enrollments_on_season_id"
  end

  create_table "managers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_managers_on_email", unique: true
  end

  create_table "matches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "canceled_at"
    t.uuid "canceled_by_id"
    t.integer "comments_count", default: 0, null: false
    t.datetime "comments_disabled_since"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "kind", default: 0, null: false
    t.string "notes"
    t.uuid "place_id"
    t.date "play_date"
    t.integer "play_time"
    t.datetime "predictions_disabled_since"
    t.datetime "published_at"
    t.boolean "ranking_counted", default: true, null: false
    t.integer "reactions_count", default: 0, null: false
    t.datetime "rejected_at"
    t.datetime "requested_at"
    t.datetime "reviewed_at"
    t.uuid "season_id", null: false
    t.integer "set1_side1_score"
    t.integer "set1_side2_score"
    t.integer "set2_side1_score"
    t.integer "set2_side2_score"
    t.integer "set3_side1_score"
    t.integer "set3_side2_score"
    t.datetime "updated_at", null: false
    t.integer "winner_side"
    t.index ["canceled_by_id"], name: "index_matches_on_canceled_by_id"
    t.index ["place_id"], name: "index_matches_on_place_id"
    t.index ["season_id"], name: "index_matches_on_season_id"
  end

  create_table "noticed_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.uuid "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.datetime "read_at", precision: nil
    t.uuid "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "places", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_places_on_name", unique: true
  end

  create_table "player_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "player_id", null: false
    t.uuid "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "tag_id"], name: "index_player_tags_on_player_id_and_tag_id", unique: true
    t.index ["player_id"], name: "index_player_tags_on_player_id"
    t.index ["tag_id"], name: "index_player_tags_on_tag_id"
  end

  create_table "players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "anonymized_at"
    t.integer "birth_year"
    t.datetime "cant_play_since"
    t.datetime "comments_disabled_since"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.datetime "open_to_play_since"
    t.string "phone_nr"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_players_on_confirmation_token", unique: true
    t.index ["email"], name: "index_players_on_email", unique: true
    t.index ["phone_nr"], name: "index_players_on_phone_nr", unique: true
    t.index ["reset_password_token"], name: "index_players_on_reset_password_token", unique: true
  end

  create_table "predictions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "match_id", null: false
    t.uuid "player_id", null: false
    t.integer "side", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "player_id"], name: "index_predictions_on_match_id_and_player_id", unique: true
    t.index ["match_id"], name: "index_predictions_on_match_id"
    t.index ["player_id"], name: "index_predictions_on_player_id"
  end

  create_table "reactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "player_id", null: false
    t.uuid "reactionable_id", null: false
    t.string "reactionable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_reactions_on_player_id"
    t.index ["reactionable_type", "reactionable_id"], name: "index_reactions_on_reactionable"
  end

  create_table "seasons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "max_matches_with_opponent", default: 2, null: false
    t.integer "max_pending_matches", default: 3, null: false
    t.string "name", null: false
    t.integer "performance_play_off_size", default: 4, null: false
    t.string "performance_player_tag_label", default: "reg.", null: false
    t.text "play_off_conditions"
    t.integer "play_off_min_matches_count", default: 10, null: false
    t.integer "position", null: false
    t.integer "regular_a_play_off_size", default: 8, null: false
    t.integer "regular_b_play_off_size", default: 16, null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tournaments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "begin_date"
    t.integer "color_base", null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "comments_disabled_since"
    t.datetime "created_at", null: false
    t.string "draw_url"
    t.date "end_date"
    t.string "main_info", null: false
    t.string "name", null: false
    t.uuid "place_id"
    t.datetime "published_at"
    t.integer "reactions_count", default: 0, null: false
    t.string "schedule_url"
    t.uuid "season_id", null: false
    t.text "side_info"
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_tournaments_on_place_id"
    t.index ["season_id"], name: "index_tournaments_on_season_id"
  end

  add_foreign_key "articles", "managers"
  add_foreign_key "articles", "seasons"
  add_foreign_key "assignments", "matches"
  add_foreign_key "assignments", "players"
  add_foreign_key "comments", "players"
  add_foreign_key "enrollments", "players"
  add_foreign_key "enrollments", "seasons"
  add_foreign_key "matches", "places"
  add_foreign_key "matches", "seasons"
  add_foreign_key "player_tags", "players"
  add_foreign_key "player_tags", "tags"
  add_foreign_key "predictions", "matches"
  add_foreign_key "predictions", "players"
  add_foreign_key "reactions", "players"
  add_foreign_key "tournaments", "places"
  add_foreign_key "tournaments", "seasons"
end
