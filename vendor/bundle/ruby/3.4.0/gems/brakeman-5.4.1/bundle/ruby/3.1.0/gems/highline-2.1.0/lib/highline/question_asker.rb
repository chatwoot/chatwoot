# encoding: utf-8

class HighLine
  # Deals with the task of "asking" a question
  class QuestionAsker
    # @return [Question] question to be asked
    attr_reader :question

    include CustomErrors

    # To do its work QuestionAsker needs a Question
    # to be asked and a HighLine context where to
    # direct output.
    #
    # @param question [Question] question to be asked
    # @param highline [HighLine] context
    def initialize(question, highline)
      @question = question
      @highline = highline
    end

    #
    # Gets just one answer, as opposed to #gather_answers
    #
    # @return [String] answer
    def ask_once
      question.show_question(@highline)

      begin
        question.get_response_or_default(@highline)
        raise NotValidQuestionError unless question.valid_answer?

        question.convert

        if question.confirm
          confirmation = @highline.send(:confirm, question)
          raise NoConfirmationQuestionError unless confirmation
        end
      rescue ExplainableError => e
        explain_error(e.explanation_key)
        retry
      rescue ArgumentError => error
        case error.message
        when /ambiguous/
          # the assumption here is that OptionParser::Completion#complete
          # (used for ambiguity resolution) throws exceptions containing
          # the word 'ambiguous' whenever resolution fails
          explain_error(:ambiguous_completion)
          retry
        when /invalid value for/
          explain_error(:invalid_type)
          retry
        else
          raise
        end
      end

      question.answer
    end

    ## Multiple questions

    #
    # Collects an Array/Hash full of answers as described in
    # HighLine::Question.gather().
    #
    # @return [Array, Hash] answers
    def gather_answers
      verify_match = question.verify_match
      answers = []

      # when verify_match is set this loop will repeat until unique_answers == 1
      loop do
        answers = gather_answers_based_on_type

        break unless verify_match &&
                     (@highline.send(:unique_answers, answers).size > 1)

        explain_error(:mismatch)
      end

      verify_match ? @highline.send(:last_answer, answers) : answers
    end

    # Gather multiple integer values based on {Question#gather} count
    # @return [Array] answers
    def gather_integer
      gather_with_array do |answers|
        (question.gather - 1).times { answers << ask_once }
      end
    end

    # Gather multiple values until any of them matches the
    # {Question#gather} Regexp.
    # @return [Array] answers
    def gather_regexp
      gather_with_array do |answers|
        answers << ask_once until answer_matches_regex(answers.last)
        answers.pop
      end
    end

    # Gather multiple values and store them on a Hash
    # with keys provided by the Hash on {Question#gather}
    # @return [Hash]
    def gather_hash
      sorted_keys = question.gather.keys.sort_by(&:to_s)
      sorted_keys.each_with_object({}) do |key, answers|
        @highline.key = key
        answers[key]  = ask_once
      end
    end

    private

    ## Delegate to Highline
    def explain_error(explanation_key) # eg: :not_valid, :not_in_range
      @highline.say(question.final_response(explanation_key))
      @highline.say(question.ask_on_error_msg)
    end

    def gather_with_array
      [].tap do |answers|
        answers << ask_once
        question.template = ""

        yield answers
      end
    end

    def answer_matches_regex(answer)
      if question.gather.is_a?(::String) || question.gather.is_a?(Symbol)
        answer.to_s == question.gather.to_s
      elsif question.gather.is_a?(Regexp)
        answer.to_s =~ question.gather
      end
    end

    def gather_answers_based_on_type
      case question.gather
      when Integer
        gather_integer
      when ::String, Symbol, Regexp
        gather_regexp
      when Hash
        gather_hash
      end
    end
  end
end
