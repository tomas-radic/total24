class MatchCommentedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Komentár k zápasu #{record.name}"
    end

    def url
      match_path(record)
    end
  end
end
