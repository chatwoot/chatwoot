require 'forwardable'

require 'ruby-progressbar/components/bar'
require 'ruby-progressbar/components/percentage'
require 'ruby-progressbar/components/rate'
require 'ruby-progressbar/components/time'
require 'ruby-progressbar/components/title'
require 'ruby-progressbar/format/formatter'
require 'ruby-progressbar/format/string'
require 'ruby-progressbar/outputs/non_tty'
require 'ruby-progressbar/outputs/tty'
require 'ruby-progressbar/progress'
require 'ruby-progressbar/projector'
require 'ruby-progressbar/timer'

class   ProgressBar
class   Base
  extend Forwardable

  # rubocop:disable Layout/HeredocIndentation
  SMOOTHING_DEPRECATION_WARNING = <<-HEREDOC.tr("\n", ' ')
WARNING: Passing the 'smoothing' option is deprecated  and will be removed
in version 2.0. Please pass { projector: { type: 'smoothing', strength: 0.x }}.
For more information on why this change is happening,  visit
https://github.com/jfelchner/ruby-progressbar/wiki/Upgrading
  HEREDOC

  RUNNING_AVERAGE_RATE_DEPRECATION_WARNING = <<-HEREDOC.tr("\n", ' ')
WARNING: Passing the 'running_average_rate' option is deprecated  and will be removed
in version 2.0. Please pass { projector: { type: 'smoothing', strength: 0.x }}.
For more information on why this change is happening,  visit
https://github.com/jfelchner/ruby-progressbar/wiki/Upgrading
  HEREDOC
  # rubocop:enable Layout/HeredocIndentation

  def_delegators :output,
                 :clear,
                 :log,
                 :refresh

  def_delegators :progressable,
                 :progress,
                 :total

  def initialize(options = {}) # rubocop:disable Metrics/AbcSize
    options[:projector] ||= {}

    self.autostart    = options.fetch(:autostart,  true)
    self.autofinish   = options.fetch(:autofinish, true)
    self.finished     = false

    self.timer        = Timer.new(options)
    projector_opts    = if options[:projector].any?
                          options[:projector]
                        elsif options[:smoothing]
                          warn SMOOTHING_DEPRECATION_WARNING

                          { :strength => options[:smoothing] }
                        elsif options[:running_average_rate]
                          warn RUNNING_AVERAGE_RATE_DEPRECATION_WARNING

                          { :strength => options[:smoothing] }
                        else
                          {}
                        end
    self.projector    = Projector.
                          from_type(options[:projector][:type]).
                          new(projector_opts)
    self.progressable = Progress.new(options)

    options = options.merge(:progress  => progressable,
                            :projector => projector,
                            :timer     => timer)

    self.title_component      = Components::Title.new(options)
    self.bar_component        = Components::Bar.new(options)
    self.percentage_component = Components::Percentage.new(options)
    self.rate_component       = Components::Rate.new(options)
    self.time_component       = Components::Time.new(options)

    self.output       = Output.detect(options.merge(:bar => self))
    @format           = Format::String.new(output.resolve_format(options[:format]))

    start :at => options[:starting_at] if autostart
  end

  def start(options = {})
    timer.start
    update_progress(:start, options)
  end

  def finish
    return if finished?

    output.with_refresh do
      self.finished = true
      progressable.finish
      timer.stop
    end
  end

  def pause
    output.with_refresh { timer.pause } unless paused?
  end

  def stop
    output.with_refresh { timer.stop } unless stopped?
  end

  def resume
    output.with_refresh { timer.resume } if stopped?
  end

  def reset
    output.with_refresh do
      self.finished = false
      progressable.reset
      projector.reset
      timer.reset
    end
  end

  def stopped?
    timer.stopped? || finished?
  end

  alias paused? stopped?

  def finished?
    finished || (autofinish && progressable.finished?)
  end

  def started?
    timer.started?
  end

  def decrement
    update_progress(:decrement)
  end

  def increment
    update_progress(:increment)
  end

  def progress=(new_progress)
    update_progress(:progress=, new_progress)
  end

  def total=(new_total)
    update_progress(:total=, new_total)
  end

  def progress_mark=(mark)
    output.refresh_with_format_change { bar_component.progress_mark = mark }
  end

  def remainder_mark=(mark)
    output.refresh_with_format_change { bar_component.remainder_mark = mark }
  end

  def title
    title_component.title
  end

  def title=(title)
    output.refresh_with_format_change { title_component.title = title }
  end

  def to_s(new_format = nil)
    self.format = new_format if new_format

    Format::Formatter.process(@format, output.length, self)
  end

  # rubocop:disable Metrics/AbcSize, Layout/LineLength
  def to_h
    {
      'output_stream'                       => output.__send__(:stream),
      'length'                              => output.length,
      'title'                               => title_component.title,
      'progress_mark'                       => bar_component.progress_mark,
      'remainder_mark'                      => bar_component.remainder_mark,
      'progress'                            => progressable.progress,
      'total'                               => progressable.total,
      'percentage'                          => progressable.percentage_completed_with_precision.to_f,
      'elapsed_time_in_seconds'             => time_component.__send__(:timer).elapsed_seconds,
      'estimated_time_remaining_in_seconds' => time_component.__send__(:estimated_seconds_remaining),
      'base_rate_of_change'                 => rate_component.__send__(:base_rate),
      'scaled_rate_of_change'               => rate_component.__send__(:scaled_rate),
      'unknown_progress_animation_steps'    => bar_component.upa_steps,
      'throttle_rate'                       => output.__send__(:throttle).rate,
      'started?'                            => started?,
      'stopped?'                            => stopped?,
      'finished?'                           => finished?
    }
  end
  # rubocop:enable Metrics/AbcSize, Layout/LineLength

  def inspect
    "#<ProgressBar:#{progress}/#{total || 'unknown'}>"
  end

  def format=(other)
    output.refresh_with_format_change do
      @format = Format::String.new(other || output.default_format)
    end
  end

  alias format format=

  protected

  attr_accessor :output,
                :projector,
                :timer,
                :progressable,
                :title_component,
                :bar_component,
                :percentage_component,
                :rate_component,
                :time_component,
                :autostart,
                :autofinish,
                :finished

  def update_progress(*args)
    output.with_refresh do
      progressable.__send__(*args)
      projector.__send__(*args)
      timer.stop if finished?
    end
  end
end
end
