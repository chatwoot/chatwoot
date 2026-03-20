module CustomExceptions::Webhook # rubocop:disable Style/ClassAndModuleChildren
  class RetriableError < CustomExceptions::Base
    def initialize(message)
      super(message: message)
    end

    def message
      @data[:message]
    end
  end
end
