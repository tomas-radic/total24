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
end
