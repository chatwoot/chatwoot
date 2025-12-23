module ChildProcess
  class Error < StandardError
  end

  class TimeoutError < Error
  end

  class SubclassResponsibility < Error
  end

  class InvalidEnvironmentVariable < Error
  end

  class LaunchError < Error
  end
end
