module ChildProcess
  class AbstractIO
    attr_reader :stderr, :stdout, :stdin

    def inherit!
      @stdout = STDOUT
      @stderr = STDERR
    end

    def stderr=(io)
      check_type io
      @stderr = io
    end

    def stdout=(io)
      check_type io
      @stdout = io
    end

    #
    # @api private
    #

    def _stdin=(io)
      check_type io
      @stdin = io
    end

    private

    def check_type(io)
      raise SubclassResponsibility, "check_type"
    end

  end
end
