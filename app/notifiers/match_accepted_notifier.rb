class MatchAcceptedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{MatchPresenter.new(record).side_names(2)} akceptoval/a výzvu"
    end

    def url
      match_path(record)
    end
  end
end
