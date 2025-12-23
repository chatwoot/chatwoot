require "test_helper"

class OptionTest < Minitest::Spec
  describe "positional and kws" do
    def assert_result(result, block = nil)
      _(result).must_equal([{a: 1}, 2, {b: 3}, block])

      _(positional.inspect).must_equal %({:a=>1})
      _(keywords.inspect).must_equal %({:a=>2, :b=>3})
    end

    class Step
      def with_positional_and_keywords(options, a: nil, **more_options, &block)
        [options, a, more_options, block]
      end
    end

    WITH_POSITIONAL_AND_KEYWORDS = ->(options, a: nil, **more_options, &block) do
      [options, a, more_options, block]
    end

    class WithPositionalAndKeywords
      def self.call(options, a: nil, **more_options, &block)
        [options, a, more_options, block]
      end
    end

    let(:positional) { {a: 1} }
    let(:keywords)   { {a: 2, b: 3} }

    let(:block) { ->(*) { snippet } }

    describe ":method" do
      let(:option) { Trailblazer::Option(:with_positional_and_keywords) }

      it "passes through all args" do
        step = Step.new

        # positional = { a: 1 }
        # keywords   = { a: 2, b: 3 }
        assert_result option.(positional, keyword_arguments: keywords, exec_context: step)
      end

      it "allows passing a block, too" do
        step = Step.new

        assert_result option.(positional, keyword_arguments: keywords, exec_context: step, &block), block
      end
    end

    describe "lambda" do
      let(:option) { Trailblazer::Option(WITH_POSITIONAL_AND_KEYWORDS) }

      it "-> {} lambda" do
        step = Step.new

        assert_result option.(positional, **{keyword_arguments: keywords, exec_context: step})
      end
    end

    describe "Callable" do
      let(:option) { Trailblazer::Option(WithPositionalAndKeywords) }

      it "passes through all args" do
        assert_result option.(positional, keyword_arguments: keywords, exec_context: nil)
      end

      it "allows passing a block, too" do
        assert_result option.(positional, keyword_arguments: keywords, exec_context: nil, &block), block
      end
    end
  end

  describe "positionals" do
    def assert_result_pos(result)
      _(result).must_equal([1, 2, [3, 4]])
      _(positionals).must_equal [1, 2, 3, 4]
    end

    # In Ruby < 3.0, {*args} will grab both positionals and keyword arguments.
    class Step
      def with_positionals(a, b, *args)
        [a, b, args]
      end
    end

    WITH_POSITIONALS = ->(a, b, *args) do
      [a, b, args]
    end

    class WithPositionals
      def self.call(a, b, *args)
        [a, b, args]
      end
    end

    let(:positionals) { [1, 2, 3, 4] }

    it ":method" do
      step = Step.new

      option = Trailblazer::Option(:with_positionals)

      assert_result_pos option.(*positionals, exec_context: step)
    end

    it "-> {} lambda" do
      option = Trailblazer::Option(WITH_POSITIONALS)

      assert_result_pos option.(*positionals, exec_context: "something")
    end

    it "callable" do
      option = Trailblazer::Option(WithPositionals)

      assert_result_pos option.(*positionals, exec_context: "something")
    end
  end

  describe "keywords" do
    def assert_result_kws(result)
      _(keywords).must_equal({ a: 1, b: 2, c: 3, d: 4 })
      _(result).must_equal([1, 2, { c: 3, d: 4 }])
    end

    # In Ruby < 3.0, {*args} will grab both positionals and keyword arguments.
    class Step
      def with_keywords(a:, b:, **rest)
        [a, b, rest]
      end
    end

    WITH_KEYWORDS = ->(a:, b:, **rest) do
      [a, b, rest]
    end

    class WithKeywords
      def self.call(a:, b:, **rest)
        [a, b, rest]
      end
    end

    let(:keywords) { { a: 1, b: 2, c: 3, d: 4 } }

    it ":method" do
      step = Step.new

      option = Trailblazer::Option(:with_keywords)

      assert_result_kws option.(keyword_arguments: keywords, exec_context: step)
    end

    it "-> {} lambda" do
      option = Trailblazer::Option(WITH_KEYWORDS)

      assert_result_kws option.(keyword_arguments: keywords, exec_context: "something")
    end

    it "callable" do
      option = Trailblazer::Option(WithKeywords)

      assert_result_kws option.(keyword_arguments: keywords, exec_context: "something")
    end
  end

  describe "no arguments" do
    def assert_result_no_args(result)
      _(result).must_equal([])
    end

    class Step
      def with_no_args
        []
      end
    end

    class WithNoArgs
      def self.call
        []
      end
    end

    WITH_NO_ARGS = -> { [] }

    it ":method" do
      step = Step.new

      option = Trailblazer::Option(:with_no_args)

      assert_result_no_args option.(exec_context: step)
    end

    it "-> {} lambda" do
      option = Trailblazer::Option(WITH_NO_ARGS)

      assert_result_no_args option.(exec_context: "something")
    end

    it "callable" do
      option = Trailblazer::Option(WithNoArgs)

      assert_result_no_args option.(exec_context: "something")
    end
  end
end
