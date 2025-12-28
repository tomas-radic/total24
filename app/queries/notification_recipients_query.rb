class NotificationRecipientsQuery < ApplicationQuery
  def initialize(notification_subject, notifier_class, exclude: [])
    @notification_subject = notification_subject
    @notifier_class = notifier_class
    @exclude = exclude
  end

  def call
    @relation = recipients
    exclude_notified_recipients
    apply_explicitly_excluded

    @relation
  end

  private

  def recipients
    player_ids = Comment.where(commentable: @notification_subject).distinct.pluck(:player_id)

    case @notification_subject.class.to_s
    when 'Match'
      player_ids += @notification_subject.assignments.map(&:player_id)
    end

    Player.active.where(id: player_ids.uniq)
  end

  def exclude_notified_recipients
    @relation = @relation.where.not(
      id: Noticed::Notification
            .where(type: "#{@notifier_class}::Notification")
            .where(seen_at: nil)
            .joins(:event)
            .where(noticed_events: { record: @notification_subject })
            .select(:recipient_id))
  end

  def apply_explicitly_excluded
    @relation = @relation.where.not(id: @exclude)
  end
end
