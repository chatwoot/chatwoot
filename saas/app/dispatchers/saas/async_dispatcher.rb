# frozen_string_literal: true

module Saas::AsyncDispatcher
  def listeners
    super + [AiAgentListener.instance]
  end
end
