# coding: utf-8

require "forwardable"

class HighLine
  class Question
    # It provides all answer conversion flow.
    class AnswerConverter
      extend Forwardable

      def_delegators :@question,
                     :answer, :answer=, :check_range,
                     :directory, :answer_type, :choices_complete

      # It should be initialized with a Question object.
      # The class will get the answer from {Question#answer}
      # and then convert it to the proper {Question#answer_type}.
      # It is mainly used by {Question#convert}
      #
      # @param question [Question]
      def initialize(question)
        @question = question
      end

      # Based on the given Question object's settings,
      # it makes the conversion and returns the answer.
      # @return [Object] the converted answer.
      def convert
        return unless answer_type

        self.answer = convert_by_answer_type
        check_range
        answer
      end

      # @return [HighLine::String] answer converted to a HighLine::String
      def to_string
        HighLine::String(answer)
      end

      # That's a weird name for a method!
      # But it's working ;-)
      define_method "to_highline::string" do
        HighLine::String(answer)
      end

      # @return [Integer] answer converted to an Integer
      def to_integer
        Kernel.send(:Integer, answer)
      end

      # @return [Float] answer converted to a Float
      def to_float
        Kernel.send(:Float, answer)
      end

      # @return [Symbol] answer converted to an Symbol
      def to_symbol
        answer.to_sym
      end

      # @return [Regexp] answer converted to a Regexp
      def to_regexp
        Regexp.new(answer)
      end

      # @return [File] answer converted to a File
      def to_file
        self.answer = choices_complete(answer)
        File.open(File.join(directory.to_s, answer.last))
      end

      # @return [Pathname] answer converted to an Pathname
      def to_pathname
        self.answer = choices_complete(answer)
        Pathname.new(File.join(directory.to_s, answer.last))
      end

      # @return [Array] answer converted to an Array
      def to_array
        self.answer = choices_complete(answer)
        answer.last
      end

      # @return [Proc] answer converted to an Proc
      def to_proc
        answer_type.call(answer)
      end

      private

      def convert_by_answer_type
        if answer_type.respond_to? :parse
          answer_type.parse(answer)
        elsif answer_type.is_a? Class
          send("to_#{answer_type.name.downcase}")
        else
          send("to_#{answer_type.class.name.downcase}")
        end
      end
    end
  end
end
