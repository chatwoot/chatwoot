# frozen_string_literal: true

module WebMock

  class ResponsesSequence

    attr_accessor :times_to_repeat

    def initialize(responses)
      @times_to_repeat = 1
      @responses = responses
      @current_position = 0
    end

    def end?
      @times_to_repeat == 0
    end

    def next_response
      if @times_to_repeat > 0
        response = @responses[@current_position]
        increase_position
        response
      else
        @responses.last
      end
    end

    private

    def increase_position
      if @current_position == (@responses.length - 1)
        @current_position = 0
        @times_to_repeat -= 1
      else
        @current_position += 1
      end
    end

  end

end
