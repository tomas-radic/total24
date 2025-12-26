class NewCommentNotifier < TurboStreamNotifier
  notification_methods do
    def message
      case record.class.to_s
      when "Match"
        "Nový komentár k zápasu #{MatchPresenter.new(record).label}"
      when "Tournament"
        "Nový komentár k turnaju #{record.name}"
      end
    end

    def url
      case record.class.to_s
      when "Match"
        "#{match_url(record)}#comments"
      when "Tournament"
        "#{tournament_url(record)}#comments"
      end

    end
  end
end
