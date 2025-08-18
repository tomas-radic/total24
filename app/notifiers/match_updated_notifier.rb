class MatchUpdatedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Zmena zápasu #{record.name}"
    end

    def url
      match_path(record)
    end
  end
end
