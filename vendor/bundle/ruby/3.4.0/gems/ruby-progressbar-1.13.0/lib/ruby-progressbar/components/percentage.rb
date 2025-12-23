class   ProgressBar
module  Components
class   Percentage
  attr_accessor :progress

  def initialize(options = {})
    self.progress = options[:progress]
  end

  def percentage
    progress.percentage_completed.to_s
  end

  def justified_percentage
    progress.percentage_completed.to_s.rjust(3)
  end

  def percentage_with_precision
    progress.percentage_completed_with_precision
  end

  def justified_percentage_with_precision
    progress.percentage_completed_with_precision.to_s.rjust(6)
  end
end
end
end
