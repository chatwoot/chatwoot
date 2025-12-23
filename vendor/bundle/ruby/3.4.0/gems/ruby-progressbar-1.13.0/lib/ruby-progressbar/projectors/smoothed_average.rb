class   ProgressBar
module  Projectors
class   SmoothedAverage
  DEFAULT_STRENGTH           = 0.1
  DEFAULT_BEGINNING_POSITION = 0

  attr_accessor :samples,
                :strength
  attr_reader   :projection

  def initialize(options = {})
    self.samples    = []
    self.projection = 0.0
    self.strength   = options[:strength] || DEFAULT_STRENGTH

    start(:at => DEFAULT_BEGINNING_POSITION)
  end

  def start(options = {})
    self.projection = 0.0
    self.progress   = samples[0] = (options[:at] || progress)
  end

  def decrement
    self.progress -= 1
  end

  def increment
    self.progress += 1
  end

  def progress
    samples[1]
  end

  def total=(_new_total); end

  def reset
    start(:at => samples[0])
  end

  def progress=(new_progress)
    samples[1] = new_progress
    self.projection = \
      self.class.calculate(
        @projection,
        absolute,
        strength
      )
  end

  def none?
    projection.zero?
  end

  def self.calculate(current_projection, new_value, rate)
    (new_value * (1.0 - rate)) + (current_projection * rate)
  end

  protected

  attr_writer :projection

  private

  def absolute
    samples[1] - samples[0]
  end
end
end
end
