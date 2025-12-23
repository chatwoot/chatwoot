# encoding: utf-8

class HighLine
  # Internal HighLine errors.
  module CustomErrors
    # An error that responds to :explanation_key
    class ExplainableError < StandardError
      # Explanation key as Symbol or nil. Used to
      # select the proper error message to be displayed.
      # @return [nil, Symbol] explanation key to get the
      #   proper error message.
      def explanation_key
        nil
      end
    end

    # Bare Question error
    class QuestionError < ExplainableError
      # (see ExplainableError#explanation_key)
      def explanation_key
        nil
      end
    end

    # Invalid Question error
    class NotValidQuestionError < ExplainableError
      # (see ExplainableError#explanation_key)
      def explanation_key
        :not_valid
      end
    end

    # Out of Range Question error
    class NotInRangeQuestionError < ExplainableError
      # (see ExplainableError#explanation_key)
      def explanation_key
        :not_in_range
      end
    end

    # Unconfirmed Question error
    class NoConfirmationQuestionError < ExplainableError
      # (see ExplainableError#explanation_key)
      def explanation_key
        nil
      end
    end

    # Unavailable auto complete error
    class NoAutoCompleteMatch < ExplainableError
      # (see ExplainableError#explanation_key)
      def explanation_key
        :no_completion
      end
    end
  end
end
