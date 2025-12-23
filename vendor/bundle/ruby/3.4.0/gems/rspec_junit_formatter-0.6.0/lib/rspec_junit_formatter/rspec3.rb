# frozen_string_literal: true

class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self,
    :start,
    :stop,
    :dump_summary

  def start(notification)
    @start_notification = notification
    @started = Time.now
    super
  end

  def stop(notification)
    @examples_notification = notification
  end

  def dump_summary(notification)
    @summary_notification = notification
    without_color { xml_dump }
  end

private

  attr_reader :started

  def example_count
    @summary_notification.example_count
  end

  def pending_count
    @summary_notification.pending_count
  end

  def failure_count
    @summary_notification.failure_count
  end

  def duration
    @summary_notification.duration
  end

  def examples
    @examples_notification.notifications
  end

  def error_count
    # Introduced in rspec 3.6
    if @summary_notification.respond_to?(:errors_outside_of_examples_count)
      @summary_notification.errors_outside_of_examples_count
    else
      0
    end
  end

  def result_of(notification)
    notification.example.execution_result.status
  end

  def example_group_file_path_for(notification)
    metadata = notification.example.metadata[:example_group]
    while parent_metadata = metadata[:parent_example_group]
      metadata = parent_metadata
    end
    metadata[:file_path]
  end

  def classname_for(notification)
    fp = example_group_file_path_for(notification)
    fp.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(%r{\A\.+|\.+\Z}, "")
  end

  def duration_for(notification)
    notification.example.execution_result.run_time
  end

  def description_for(notification)
    notification.example.full_description
  end

  def failure_type_for(example)
    exception_for(example).class.name
  end

  def failure_message_for(example)
    strip_diff_colors(exception_for(example).to_s)
  end

  def failure_for(notification)
    strip_diff_colors(notification.message_lines.join("\n")) << "\n" << notification.formatted_backtrace.join("\n")
  end

  def exception_for(notification)
    notification.example.execution_result.exception
  end

  # rspec makes it really difficult to swap in configuration temporarily due to
  # the way it cascades defaults, command line arguments, and user
  # configuration. This method makes sure configuration gets swapped in
  # correctly, but also that the original state is definitely restored.
  def swap_rspec_configuration(key, value)
    unset = Object.new
    force = RSpec.configuration.send(:value_for, key) { unset }
    if unset.equal?(force)
      previous = RSpec.configuration.send(key)
      RSpec.configuration.send(:"#{key}=", value)
    else
      RSpec.configuration.force({key => value})
    end
    yield
  ensure
    if unset.equal?(force)
      RSpec.configuration.send(:"#{key}=", previous)
    else
      RSpec.configuration.force({key => force})
    end
  end

  # Completely gross hack for absolutely forcing off colorising for the
  # duration of a block.
  if RSpec.configuration.respond_to?(:color_mode=)
    def without_color(&block)
      swap_rspec_configuration(:color_mode, :off, &block)
    end
  elsif RSpec.configuration.respond_to?(:color=)
    def without_color(&block)
      swap_rspec_configuration(:color, false, &block)
    end
  else
    warn 'rspec_junit_formatter cannot prevent colorising due to an unexpected RSpec.configuration format'
    def without_color
      yield
    end
  end

  def stdout_for(example_notification)
    example_notification.example.metadata[:stdout]
  end

  def stderr_for(example_notification)
    example_notification.example.metadata[:stderr]
  end
end

# rspec-core 3.0.x forgot to mark this as a module function which causes:
#
#   NoMethodError: undefined method `wrap' for RSpec::Core::Notifications::NullColorizer:Class
#     .../rspec-core-3.0.4/lib/rspec/core/notifications.rb:229:in `add_shared_group_line'
#     .../rspec-core-3.0.4/lib/rspec/core/notifications.rb:157:in `message_lines'
#
if defined?(RSpec::Core::Notifications::NullColorizer) && RSpec::Core::Notifications::NullColorizer.is_a?(Class) && !RSpec::Core::Notifications::NullColorizer.respond_to?(:wrap)
  RSpec::Core::Notifications::NullColorizer.class_eval do
    def self.wrap(*args)
      new.wrap(*args)
    end
  end
end
