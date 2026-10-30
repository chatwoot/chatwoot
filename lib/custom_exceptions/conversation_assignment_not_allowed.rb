# frozen_string_literal: true

class CustomExceptions::ConversationAssignmentNotAllowed < CustomExceptions::Base
  def message
    @data[:message]
  end
end
