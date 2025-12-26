class PlayerPresenter
  def initialize(player, privacy: false)
    @player = player
    @privacy = privacy
  end

  def name
    return @player.name unless @privacy

    name_parts = @player.name.split(/\s+/).reject(&:blank?)
    privacy_name_parts = []

    name_parts[1..-1].each do |np|
      privacy_name_parts << np[0] + "."
    end

    privacy_name_parts.unshift(name_parts[0]).join(" ")
  end
end
