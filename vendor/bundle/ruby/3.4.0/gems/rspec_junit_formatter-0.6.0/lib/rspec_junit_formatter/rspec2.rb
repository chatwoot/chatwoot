# frozen_string_literal: true

class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  attr_reader :started

  def start(example_count)
    @started = Time.now
    super
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    super
    xml_dump
  end

private

  def result_of(example)
    example.execution_result[:status].to_sym
  end

  def example_group_file_path_for(example)
    meta = example.metadata
    while meta[:example_group]
      meta = meta[:example_group]
    end
    meta[:file_path]
  end

  def classname_for(example)
    fp = example_group_file_path_for(example)
    fp.sub(%r{\.[^/.]+\Z}, "").gsub("/", ".").gsub(/\A\.+|\.+\Z/, "")
  end

  def duration_for(example)
    example.execution_result[:run_time]
  end

  def description_for(example)
    example.full_description
  end

  def exception_for(example)
    example.execution_result[:exception]
  end

  def failure_type_for(example)
    exception_for(example).class.name
  end

  def failure_message_for(example)
    strip_diff_colors(exception_for(example).to_s)
  end

  def failure_for(example)
    exception = exception_for(example)
    message   = strip_diff_colors(exception.message)
    backtrace = format_backtrace(exception.backtrace, example)

    if shared_group = find_shared_group(example)
      backtrace << "Shared Example Group: \"#{shared_group.metadata[:shared_group_name]}\" called from #{shared_group.metadata[:example_group][:location]}"
    end

    "#{message}\n#{backtrace.join("\n")}"
  end

  def error_count
    0
  end

  def find_shared_group(example)
    group_and_parent_groups(example).find { |group| group.metadata[:shared_group_name] }
  end

  def group_and_parent_groups(example)
    example.example_group.parent_groups + [example.example_group]
  end

  def stdout_for(example)
    example.metadata[:stdout]
  end

  def stderr_for(example)
    example.metadata[:stderr]
  end
end
