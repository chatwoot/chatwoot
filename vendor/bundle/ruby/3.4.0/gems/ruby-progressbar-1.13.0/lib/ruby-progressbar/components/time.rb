###
# OOB = 'Out of Bounds'
#
class   ProgressBar
module  Components
class   Time
  TIME_FORMAT            = '%02d:%02d:%02d'.freeze
  OOB_TIME_FORMATS       = [:unknown, :friendly, nil].freeze
  OOB_LIMIT_IN_HOURS     = 99
  OOB_UNKNOWN_TIME_TEXT  = '??:??:??'.freeze
  OOB_FRIENDLY_TIME_TEXT = '> 4 Days'.freeze
  NO_TIME_ELAPSED_TEXT   = '--:--:--'.freeze
  ESTIMATED_LABEL        = ' ETA'.freeze
  ELAPSED_LABEL          = 'Time'.freeze
  WALL_CLOCK_FORMAT      = '%H:%M:%S'.freeze
  OOB_TEXT_TO_FORMAT     = {
    :unknown  => OOB_UNKNOWN_TIME_TEXT,
    :friendly => OOB_FRIENDLY_TIME_TEXT
  }.freeze

  def initialize(options = {})
    self.timer     = options[:timer]
    self.progress  = options[:progress]
    self.projector = options[:projector]
  end

  def estimated_with_label(out_of_bounds_time_format = nil)
    "#{ESTIMATED_LABEL}: #{estimated(out_of_bounds_time_format)}"
  end

  def elapsed_with_label
    "#{ELAPSED_LABEL}: #{elapsed}"
  end

  def estimated_with_no_oob
    estimated_with_elapsed_fallback(nil)
  end

  def estimated_with_unknown_oob
    estimated_with_elapsed_fallback(:unknown)
  end

  def estimated_with_friendly_oob
    estimated_with_elapsed_fallback(:friendly)
  end

  def estimated_wall_clock
    return timer.stopped_at.strftime(WALL_CLOCK_FORMAT) if progress.finished?
    return NO_TIME_ELAPSED_TEXT unless timer.started?

    memo_estimated_seconds_remaining = estimated_seconds_remaining
    return NO_TIME_ELAPSED_TEXT unless memo_estimated_seconds_remaining

    (timer.now + memo_estimated_seconds_remaining).
      strftime(WALL_CLOCK_FORMAT)
  end

  protected

  attr_accessor :timer,
                :progress,
                :projector

  private

  def estimated(out_of_bounds_time_format)
    memo_estimated_seconds_remaining = estimated_seconds_remaining

    return OOB_UNKNOWN_TIME_TEXT unless memo_estimated_seconds_remaining

    hours, minutes, seconds = timer.divide_seconds(memo_estimated_seconds_remaining)

    if hours > OOB_LIMIT_IN_HOURS && out_of_bounds_time_format
      OOB_TEXT_TO_FORMAT.fetch(out_of_bounds_time_format)
    else
      TIME_FORMAT % [hours, minutes, seconds]
    end
  end

  def elapsed
    return NO_TIME_ELAPSED_TEXT unless timer.started?

    hours, minutes, seconds = timer.divide_seconds(timer.elapsed_whole_seconds)

    TIME_FORMAT % [hours, minutes, seconds]
  end

  def estimated_with_elapsed_fallback(out_of_bounds_time_format)
    return elapsed_with_label if progress.finished?

    estimated_with_label(out_of_bounds_time_format)
  end

  def estimated_seconds_remaining
    return if progress.unknown? || projector.none? || progress.none? || timer.stopped? || timer.reset?

    (timer.elapsed_seconds * ((progress.total / projector.projection) - 1)).round
  end
end
end
end
