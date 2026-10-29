# frozen_string_literal: true

module CustomExceptions::Conversation
  class AssignmentNotAllowed < CustomExceptions::Base
    def message
      @data[:message]
    end
  end
end
