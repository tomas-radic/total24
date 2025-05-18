class Player < ApplicationRecord
  include StrippedAttributes

  # Include default devise modules. Others available are:
  # :recoverable, :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable, :trackable, :confirmable

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


  attr_writer :points, :percentage, :played_matches, :won_matches

  def points
    @points || 0
  end

  def percentage
    @percentage || 0
  end

  def played_matches
    @played_matches || 0
  end

  def won_matches
    @won_matches || 0
  end

  def display_name(privacy: false)
    return name unless privacy

    name_parts = name.split(/\s+/).reject(&:blank?)
    privacy_name_parts = []

    name_parts[1..-1].each do |np|
      privacy_name_parts << np[0] + "."
    end

    privacy_name_parts.unshift(name_parts[0]).join(" ")
  end

  def season_matches(season)
    matches.published.reviewed.sorted
           .joins('join seasons on matches.competitable_type = \'Season\'')
           .where(matches: { competitable_id: season.id })
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

  def send_confirmation_notification?
    false
  end
end
