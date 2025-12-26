class MatchUpdatedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Zmena zápasu #{MatchPresenter.new(record).label}"
    end

    def url
      match_path(record)
    end
  end
end
