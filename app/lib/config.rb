module Config
  extend self

  def notifications_max_age_days
    (ENV["NOTIFICATIONS_MAX_AGE_DAYS"] || 45).to_i
  end

  def notifications_dropdown_size
    (ENV["NOTIFICATIONS_DROPDOWN_SIZE"] || 8).to_i
  end

  def refinish_match_minutes_limit
    (ENV["REFINISH_MATCH_MINUTES_LIMIT"] || 10).to_i
  end

  def registrations_enabled?
    ENV["REGISTRATIONS_ENABLED"] == "1"
  end

  def performance_player_tag_label
    ENV["PERFORMANCE_PLAYER_TAG_LABEL"] || "reg"
  end

  def before_tournament_days_notice
    (ENV["BEFORE_TOURNAMENT_DAYS_NOTICE"] || 12).to_i
  end

  def after_tournament_days_notice
    (ENV["AFTER_TOURNAMENT_DAYS_NOTICE"] || 2).to_i
  end

  def article_default_promotion_days
    (ENV["ARTICLE_DEFAULT_PROMOTION_DAYS"] || 4).to_i
  end
end
