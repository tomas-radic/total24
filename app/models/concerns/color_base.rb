module ColorBase
  extend ActiveSupport::Concern

  included do
    before_validation :set_random_color_base

    enum :color_base, {
      base_green: 0,
      base_yellow: 1,
      base_salmon: 2,
      base_red: 3
    }
  end

  def color_base_css
    color_base.gsub('_', '-') if color_base
  end


  private

  def set_random_color_base
    self.color_base ||= self.class.color_bases.keys.sample
  end
end
