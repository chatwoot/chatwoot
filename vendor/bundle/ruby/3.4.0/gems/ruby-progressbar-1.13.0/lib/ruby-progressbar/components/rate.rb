class   ProgressBar
module  Components
class   Rate
  attr_accessor :rate_scale,
                :timer,
                :progress

  def initialize(options = {})
    self.rate_scale = options[:rate_scale] || lambda { |x| x }
    self.timer      = options[:timer]
    self.progress   = options[:progress]
  end

  def rate_of_change(format_string = '%i')
    return '0' if elapsed_seconds <= 0

    format_string % scaled_rate
  end

  def rate_of_change_with_precision
    rate_of_change('%.2f')
  end

  private

  def scaled_rate
    rate_scale.call(base_rate)
  end

  def base_rate
    progress.absolute / elapsed_seconds
  end

  def elapsed_seconds
    timer.elapsed_whole_seconds.to_f
  end
end
end
end
