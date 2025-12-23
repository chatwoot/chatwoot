# frozen_string_literal: true

module MetaRequest
  class AppRequest
    attr_reader :id, :events

    def initialize(id)
      @id = id
      @events = []
    end

    def self.current
      Thread.current[:meta_request_id]
    end

    def current!
      Thread.current[:meta_request_id] = self
    end
  end
end
