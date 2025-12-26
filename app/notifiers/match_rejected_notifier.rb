class MatchRejectedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{MatchPresenter.new(record).side_names(2)} odmietol/la výzvu"
    end

    def url
      match_path(record)
    end
  end
end
