class MatchFinishedNotifier < TurboStreamNotifier
  notification_methods do
    def message
      "#{params[:finished_by].name} zapísal výsledok"
    end

    def url
      match_path(record)
    end
  end
end
