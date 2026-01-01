class Player < ApplicationRecord
  include StrippedAttributes

  # Include default devise modules. Others available are:
  # :recoverable, :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable, :trackable, :confirmable

  # region Relations
  has_many :enrollments, dependent: :destroy
  has_many :seasons, through: :enrollments
  has_many :assignments, dependent: :destroy
  has_many :matches, through: :assignments
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :player_tags, dependent: :destroy
  has_many :tags, through: :player_tags
  has_many :notifications, dependent: :destroy, as: :recipient, class_name: "Noticed::Notification"
  has_many :recent_unread_notifications, -> { unread.newest_first.limit(Config.notifications_dropdown_size) },
           as: :recipient, class_name: "Noticed::Notification"
  # endregion Relations

  # region Validations
  validates :cant_play_since, absence: true, if: -> { open_to_play_since.present? }
  validates :open_to_play_since, absence: true, if: -> { cant_play_since.present? }
  validates :phone_nr, uniqueness: true, if: -> { anonymized_at.blank? }
  validates :name,
            presence: true, uniqueness: true, if: -> { anonymized_at.blank? }
  # endregion Validations

  # region Scopes
  scope :sorted, -> { order(created_at: :desc) }
  scope :active, -> { where(anonymized_at: nil).where.not(confirmed_at: nil) }
  scope :open_to_play, -> { where.not(open_to_play_since: nil).order(open_to_play_since: :desc) }
  # endregion Scopes


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

  def anonymize!
    ActiveRecord::Base.transaction do
      matches.where(finished_at: nil).each do |match|
        match.destroy!
      end

      self.anonymized_at = Time.current
      self.phone_nr = nil
      self.birth_year = nil
      self.name = "(zmazaný hráč)"
      self.unconfirmed_email = "#{SecureRandom.hex}@anonymized.player"
      confirm
      update!(confirmed_at: nil)
    end

    self
  end

  def anonymized?
    anonymized_at.present?
  end

  def send_confirmation_notification?
    false
  end

  def active_for_authentication?
    super && !anonymized?
  end
end
