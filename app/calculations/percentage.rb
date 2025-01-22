class Percentage

  def self.calculate(count, of:)
    self.new(count, of:).calculate
  end


  def initialize(count, of:)
    @count = count
    @of = of
  end


  def calculate
    p = (@count.to_f * 100.0) / @of.to_f

    if p > 0.0 && p < 1.0
      1
    elsif p > 99.0 && p < 100.0
      99
    else
      p.round
    end
  end
end
