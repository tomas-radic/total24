xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @urls.each do |url|
    xml.url do
      xml.loc url
      xml.changefreq 'daily'
      xml.priority 0.8
    end
  end

  @articles.each do |article|
    xml.url do
      xml.loc article_url(article)
      xml.lastmod article.updated_at.to_date
      xml.changefreq 'monthly'
      xml.priority 0.6
    end
  end

  @players.each do |player|
    xml.url do
      xml.loc player_url(player)
      xml.changefreq 'weekly'
      xml.priority 0.5
    end
  end

  @tournaments.each do |tournament|
    xml.url do
      xml.loc tournament_url(tournament)
      xml.changefreq 'weekly'
      xml.priority 0.7
    end
  end
end
