# frozen_string_literal: true

# Allows to disable WebMock stubs
module DisablingStub
  def disable
    @disabled = true
  end

  def disabled?
    @disabled
  end

  WebMock::RequestStub.prepend self
end
