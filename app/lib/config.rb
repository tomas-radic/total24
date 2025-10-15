module Config
  extend self

  def notifications_max_age_days
    (ENV["NOTIFICATIONS_MAX_AGE_DAYS"] || 45).to_i
  end
end
