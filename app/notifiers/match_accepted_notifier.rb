class MatchAcceptedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{record.side_name(2)} akceptoval/a výzvu"
    end

    def url
      match_path(record)
    end
  end
end
