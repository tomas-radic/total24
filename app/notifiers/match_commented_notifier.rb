class MatchCommentedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "Komentár k zápasu #{record.name}"
    end

    def url
      "#{match_url(record)}#comments"
    end
  end
end
