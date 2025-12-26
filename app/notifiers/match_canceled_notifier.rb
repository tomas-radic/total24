class MatchCanceledNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Zápas #{MatchPresenter.new(record).label} sa zrušil"
    end

    def url
      match_path(record)
    end
  end
end
