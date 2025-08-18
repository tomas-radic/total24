class NewMatchNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{record.side_name(1)} ťa vyzval/a na zápas"
    end

    def url
      match_path(record)
    end
  end
end
