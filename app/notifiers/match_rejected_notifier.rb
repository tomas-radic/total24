class MatchRejectedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{record.side_name(2)} odmietol/la výzvu"
    end

    def url
      match_path(record)
    end
  end
end
