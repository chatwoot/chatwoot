# rubocop:disable Style/InlineComment
class   ProgressBar
class   Time
  TIME_MOCKING_LIBRARY_METHODS = [
                                   :__simple_stub__now,     # ActiveSupport
                                   :now_without_mock_time,  # Timecop
                                   :now_without_delorean,   # Delorean
                                   :now                     # Unmocked
                                 ].freeze

  def initialize(time = ::Time)
    self.time = time
  end

  def now
    time.__send__(unmocked_time_method)
  end

  def unmocked_time_method
    @unmocked_time_method ||= TIME_MOCKING_LIBRARY_METHODS.find do |method|
      time.respond_to? method
    end
  end

  protected

  attr_accessor :time
end
end
# rubocop:enable Style/InlineComment
