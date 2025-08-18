class MatchCanceledNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Zápas #{record.name} sa zrušil"
    end

    def url
      match_path(record)
    end
  end
end
