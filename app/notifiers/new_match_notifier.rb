class NewMatchNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{MatchPresenter.new(record).side_names(1)} ťa vyzval/a na zápas"
    end

    def url
      match_path(record)
    end
  end
end
