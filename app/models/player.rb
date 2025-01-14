class Player < ApplicationRecord
  include StrippedAttributes

  # Include default devise modules. Others available are:
  # :recoverable, :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable, :trackable

  # Relations -----
  has_many :enrollments, dependent: :destroy
  has_many :seasons, through: :enrollments
  has_many :assignments, dependent: :destroy
  has_many :matches, through: :assignments
  has_many :comments, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :player_tags, dependent: :destroy
  has_many :tags, through: :player_tags

  # Validations -----
  validates :cant_play_since, absence: true, if: -> { open_to_play_since.present? }
  validates :open_to_play_since, absence: true, if: -> { cant_play_since.present? }
  validates :phone_nr, uniqueness: true
  validates :name,
            presence: true, uniqueness: true

  # Scopes -----
  scope :sorted, -> { order(created_at: :desc) }


  has_stripped :email, :name, :phone_nr


  after_create_commit :update_players_list


  def won_matches(season = nil)
    if season.present?
      season.matches.reviewed.joins(:assignments)
            .where("assignments.player_id = ?", id)
            .where("assignments.side = matches.winner_side").distinct
    else
      self.matches.reviewed.joins(:assignments)
          .where("assignments.player_id = ?", id)
          .where("assignments.side = matches.winner_side").distinct
    end
  end


  def opponents(season: nil, pending: false, ranking_counted: false)
    player_matches = matches.published.where(canceled_at: nil)
    player_matches = player_matches.pending if pending
    player_matches = player_matches.ranking_counted if ranking_counted
    player_matches = player_matches.joins(:assignments).where("assignments.player_id = ?", id)

    match_ids = []

    if season.nil?
      match_ids = player_matches.map(&:id)
    else
      player_matches.each do |m|
        case m.competitable_type
        when "Season"
          match_ids << m.id if m.competitable_id == season.id
        when "Tournament"
          match_ids << m.id if m.competitable.season_id == season.id
        end
      end
    end

    Player.joins(:assignments)
          .where("assignments.match_id in (?)", match_ids)
          .where.not(id: id)
  end


  def anonymize!
    ActiveRecord::Base.transaction do
      matches.where(finished_at: nil).destroy_all

      update!(
        anonymized_at: Time.now,
        email: "#{SecureRandom.hex}@anonymized.player",
        name: "(zmazaný hráč)",
        phone_nr: nil,
        birth_year: nil
      )
    end

    self
  end


  private

  def update_players_list
    broadcast_replace_to(
      "registered_players",
      partial: "players/list",
      locals: {
        players: Player.where(anonymized_at: nil, access_denied_since: nil).order(created_at: :desc)
      },
      target: "players_list")
  end
end
