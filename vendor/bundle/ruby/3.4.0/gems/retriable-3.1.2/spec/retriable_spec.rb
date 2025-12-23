describe Retriable do
  let(:time_table_handler) do
    ->(_exception, try, _elapsed_time, next_interval) { @next_interval_table[try] = next_interval }
  end

  before(:each) do
    described_class.configure { |c| c.sleep_disabled = true }
    @tries = 0
    @next_interval_table = {}
  end

  def increment_tries
    @tries += 1
  end

  def increment_tries_with_exception(exception_class = nil)
    exception_class ||= StandardError
    increment_tries
    raise exception_class, "#{exception_class} occurred"
  end

  context "global scope extension" do
    it "cannot be called in the global scope without requiring the core_ext/kernel" do
      expect { retriable { puts "should raise NoMethodError" } }.to raise_error(NoMethodError)
    end

    it "can be called once the kernel extension is required" do
      require_relative "../lib/retriable/core_ext/kernel"

      expect { retriable { increment_tries_with_exception } }.to raise_error(StandardError)
      expect(@tries).to eq(3)
    end
  end

  context "#retriable" do
    it "raises a LocalJumpError if not given a block" do
      expect { described_class.retriable }.to raise_error(LocalJumpError)
      expect { described_class.retriable(timeout: 2) }.to raise_error(LocalJumpError)
    end

    it "stops at first try if the block does not raise an exception" do
      described_class.retriable { increment_tries }
      expect(@tries).to eq(1)
    end

    it "makes 3 tries when retrying block of code raising StandardError with no arguments" do
      expect { described_class.retriable { increment_tries_with_exception } }.to raise_error(StandardError)
      expect(@tries).to eq(3)
    end

    it "makes only 1 try when exception raised is not descendent of StandardError" do
      expect do
        described_class.retriable { increment_tries_with_exception(NonStandardError) }
      end.to raise_error(NonStandardError)

      expect(@tries).to eq(1)
    end

    it "with custom exception tries 3 times and re-raises the exception" do
      expect do
        described_class.retriable(on: NonStandardError) { increment_tries_with_exception(NonStandardError) }
      end.to raise_error(NonStandardError)

      expect(@tries).to eq(3)
    end

    it "tries 10 times when specified" do
      expect { described_class.retriable(tries: 10) { increment_tries_with_exception } }.to raise_error(StandardError)
      expect(@tries).to eq(10)
    end

    it "will timeout after 1 second" do
      expect { described_class.retriable(timeout: 1) { sleep(1.1) } }.to raise_error(Timeout::Error)
    end

    it "applies a randomized exponential backoff to each try" do
      expect do
        described_class.retriable(on_retry: time_table_handler, tries: 10) { increment_tries_with_exception }
      end.to raise_error(StandardError)

      expect(@next_interval_table).to eq(
        1 => 0.5244067512211441,
        2 => 0.9113920238761231,
        3 => 1.2406087918999114,
        4 => 1.7632403621664823,
        5 => 2.338001204738311,
        6 => 4.350816718580626,
        7 => 5.339852157217869,
        8 => 11.889873261212443,
        9 => 18.756037881636484,
        10 => nil,
      )

      expect(@tries).to eq(10)
    end

    context "with rand_factor 0.0 and an on_retry handler" do
      let(:tries) { 6 }
      let(:no_rand_timetable) { { 1 => 0.5, 2 => 0.75, 3 => 1.125 } }
      let(:args) { { on_retry: time_table_handler, rand_factor: 0.0, tries: tries } }

      it "applies a non-randomized exponential backoff to each try" do
        described_class.retriable(args) do
          increment_tries
          raise StandardError if @tries < tries
        end

        expect(@tries).to eq(tries)
        expect(@next_interval_table).to eq(no_rand_timetable.merge(4 => 1.6875, 5 => 2.53125))
      end

      it "obeys a max interval of 1.5 seconds" do
        expect do
          described_class.retriable(args.merge(max_interval: 1.5)) { increment_tries_with_exception }
        end.to raise_error(StandardError)

        expect(@next_interval_table).to eq(no_rand_timetable.merge(4 => 1.5, 5 => 1.5, 6 => nil))
      end

      it "obeys custom defined intervals" do
        interval_hash = no_rand_timetable.merge(4 => 1.5, 5 => 1.5, 6 => nil)
        intervals = interval_hash.values.compact.sort

        expect do
          described_class.retriable(on_retry: time_table_handler, intervals: intervals) do
            increment_tries_with_exception
          end
        end.to raise_error(StandardError)

        expect(@next_interval_table).to eq(interval_hash)
        expect(@tries).to eq(intervals.size + 1)
      end
    end

    context "with an array :on parameter" do
      it "handles both kinds of exceptions" do
        described_class.retriable(on: [StandardError, NonStandardError]) do
          increment_tries

          raise StandardError if @tries == 1
          raise NonStandardError if @tries == 2
        end

        expect(@tries).to eq(3)
      end
    end

    context "with a hash :on parameter" do
      let(:on_hash) { { NonStandardError => /NonStandardError occurred/ } }

      it "where the value is an exception message pattern" do
        expect do
          described_class.retriable(on: on_hash) { increment_tries_with_exception(NonStandardError) }
        end.to raise_error(NonStandardError, /NonStandardError occurred/)

        expect(@tries).to eq(3)
      end

      it "matches exception subclasses when message matches pattern" do
        expect do
          described_class.retriable(on: on_hash.merge(DifferentError => [/shouldn't happen/, /also not/])) do
            increment_tries_with_exception(SecondNonStandardError)
          end
        end.to raise_error(SecondNonStandardError, /SecondNonStandardError occurred/)

        expect(@tries).to eq(3)
      end

      it "does not retry matching exception subclass but not message" do
        expect do
          described_class.retriable(on: on_hash) do
            increment_tries
            raise SecondNonStandardError, "not a match"
          end
        end.to raise_error(SecondNonStandardError, /not a match/)

        expect(@tries).to eq(1)
      end

      it "successfully retries when the values are arrays of exception message patterns" do
        exceptions = []
        handler = ->(exception, try, _elapsed_time, _next_interval) { exceptions[try] = exception }
        on_hash = { StandardError => nil, NonStandardError => [/foo/, /bar/] }

        expect do
          described_class.retriable(tries: 4, on: on_hash, on_retry: handler) do
            increment_tries

            case @tries
            when 1
              raise NonStandardError, "foo"
            when 2
              raise NonStandardError, "bar"
            when 3
              raise StandardError
            else
              raise NonStandardError, "crash"
            end
          end
        end.to raise_error(NonStandardError, /crash/)

        expect(exceptions[1]).to be_a(NonStandardError)
        expect(exceptions[1].message).to eq("foo")
        expect(exceptions[2]).to be_a(NonStandardError)
        expect(exceptions[2].message).to eq("bar")
        expect(exceptions[3]).to be_a(StandardError)
      end
    end

    it "runs for a max elapsed time of 2 seconds" do
      described_class.configure { |c| c.sleep_disabled = false }

      expect do
        described_class.retriable(base_interval: 1.0, multiplier: 1.0, rand_factor: 0.0, max_elapsed_time: 2.0) do
          increment_tries_with_exception
        end
      end.to raise_error(StandardError)

      expect(@tries).to eq(2)
    end

    it "raises ArgumentError on invalid options" do
      expect { described_class.retriable(does_not_exist: 123) { increment_tries } }.to raise_error(ArgumentError)
    end
  end

  context "#configure" do
    it "raises NoMethodError on invalid configuration" do
      expect { described_class.configure { |c| c.does_not_exist = 123 } }.to raise_error(NoMethodError)
    end
  end

  context "#with_context" do
    let(:api_tries) { 4 }

    before do
      described_class.configure do |c|
        c.contexts[:sql] = { tries: 1 }
        c.contexts[:api] = { tries: api_tries }
      end
    end

    it "stops at first try if the block does not raise an exception" do
      described_class.with_context(:sql) { increment_tries }
      expect(@tries).to eq(1)
    end

    it "respects the context options" do
      expect { described_class.with_context(:api) { increment_tries_with_exception } }.to raise_error(StandardError)
      expect(@tries).to eq(api_tries)
    end

    it "allows override options" do
      expect do
        described_class.with_context(:sql, tries: 5) { increment_tries_with_exception }
      end.to raise_error(StandardError)

      expect(@tries).to eq(5)
    end

    it "raises an ArgumentError when the context isn't found" do
      expect { described_class.with_context(:wtf) { increment_tries } }.to raise_error(ArgumentError, /wtf not found/)
    end
  end
end
