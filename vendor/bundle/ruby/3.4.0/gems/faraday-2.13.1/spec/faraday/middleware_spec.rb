# frozen_string_literal: true

RSpec.describe Faraday::Middleware do
  subject { described_class.new(app) }
  let(:app) { double }

  describe 'options' do
    context 'when options are passed to the middleware' do
      subject { described_class.new(app, options) }
      let(:options) { { field: 'value' } }

      it 'accepts options when initialized' do
        expect(subject.options[:field]).to eq('value')
      end
    end
  end

  describe '#on_request' do
    subject do
      Class.new(described_class) do
        def on_request(env)
          # do nothing
        end
      end.new(app)
    end

    it 'is called by #call' do
      expect(app).to receive(:call).and_return(app)
      expect(app).to receive(:on_complete)
      is_expected.to receive(:call).and_call_original
      is_expected.to receive(:on_request)
      subject.call(double)
    end
  end

  describe '#on_error' do
    subject do
      Class.new(described_class) do
        def on_error(error)
          # do nothing
        end
      end.new(app)
    end

    it 'is called by #call' do
      expect(app).to receive(:call).and_raise(Faraday::ConnectionFailed)
      is_expected.to receive(:call).and_call_original
      is_expected.to receive(:on_error)

      expect { subject.call(double) }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  describe '#close' do
    context "with app that doesn't support \#close" do
      it 'should issue warning' do
        is_expected.to receive(:warn)
        subject.close
      end
    end

    context "with app that supports \#close" do
      it 'should issue warning' do
        expect(app).to receive(:close)
        is_expected.to_not receive(:warn)
        subject.close
      end
    end
  end

  describe '::default_options' do
    let(:subclass_no_options) { FaradayMiddlewareSubclasses::SubclassNoOptions }
    let(:subclass_one_option) { FaradayMiddlewareSubclasses::SubclassOneOption }
    let(:subclass_two_options) { FaradayMiddlewareSubclasses::SubclassTwoOptions }

    def build_conn(resp_middleware)
      Faraday.new do |c|
        c.adapter :test do |stub|
          stub.get('/success') { [200, {}, 'ok'] }
        end
        c.response resp_middleware
      end
    end

    RSpec.shared_context 'reset @default_options' do
      before(:each) do
        FaradayMiddlewareSubclasses::SubclassNoOptions.instance_variable_set(:@default_options, nil)
        FaradayMiddlewareSubclasses::SubclassOneOption.instance_variable_set(:@default_options, nil)
        FaradayMiddlewareSubclasses::SubclassTwoOptions.instance_variable_set(:@default_options, nil)
        Faraday::Middleware.instance_variable_set(:@default_options, nil)
      end
    end

    after(:all) do
      FaradayMiddlewareSubclasses::SubclassNoOptions.instance_variable_set(:@default_options, nil)
      FaradayMiddlewareSubclasses::SubclassOneOption.instance_variable_set(:@default_options, nil)
      FaradayMiddlewareSubclasses::SubclassTwoOptions.instance_variable_set(:@default_options, nil)
      Faraday::Middleware.instance_variable_set(:@default_options, nil)
    end

    context 'with subclass DEFAULT_OPTIONS defined' do
      include_context 'reset @default_options'

      context 'and without application options configured' do
        let(:resp1) { build_conn(:one_option).get('/success') }

        it 'has only subclass defaults' do
          expect(Faraday::Middleware.default_options).to eq(Faraday::Middleware::DEFAULT_OPTIONS)
          expect(subclass_no_options.default_options).to eq(subclass_no_options::DEFAULT_OPTIONS)
          expect(subclass_one_option.default_options).to eq(subclass_one_option::DEFAULT_OPTIONS)
          expect(subclass_two_options.default_options).to eq(subclass_two_options::DEFAULT_OPTIONS)
        end

        it { expect(resp1.body).to eq('ok') }
      end

      context "and with one application's options changed" do
        let(:resp2) { build_conn(:two_options).get('/success') }

        before(:each) do
          FaradayMiddlewareSubclasses::SubclassTwoOptions.default_options = { some_option: false }
        end

        it 'only updates default options of target subclass' do
          expect(Faraday::Middleware.default_options).to eq(Faraday::Middleware::DEFAULT_OPTIONS)
          expect(subclass_no_options.default_options).to eq(subclass_no_options::DEFAULT_OPTIONS)
          expect(subclass_one_option.default_options).to eq(subclass_one_option::DEFAULT_OPTIONS)
          expect(subclass_two_options.default_options).to eq({ some_option: false, some_other_option: false })
        end

        it { expect(resp2.body).to eq('ok') }
      end

      context "and with two applications' options changed" do
        let(:resp1) { build_conn(:one_option).get('/success') }
        let(:resp2) { build_conn(:two_options).get('/success') }

        before(:each) do
          FaradayMiddlewareSubclasses::SubclassOneOption.default_options = { some_other_option: true }
          FaradayMiddlewareSubclasses::SubclassTwoOptions.default_options = { some_option: false }
        end

        it 'updates subclasses and parent independent of each other' do
          expect(Faraday::Middleware.default_options).to eq(Faraday::Middleware::DEFAULT_OPTIONS)
          expect(subclass_no_options.default_options).to eq(subclass_no_options::DEFAULT_OPTIONS)
          expect(subclass_one_option.default_options).to eq({ some_other_option: true })
          expect(subclass_two_options.default_options).to eq({ some_option: false, some_other_option: false })
        end

        it { expect(resp1.body).to eq('ok') }
        it { expect(resp2.body).to eq('ok') }
      end
    end

    context 'with FARADAY::MIDDLEWARE DEFAULT_OPTIONS and with Subclass DEFAULT_OPTIONS' do
      before(:each) do
        stub_const('Faraday::Middleware::DEFAULT_OPTIONS', { its_magic: false })
      end

      # Must stub Faraday::Middleware::DEFAULT_OPTIONS before resetting default options
      include_context 'reset @default_options'

      context 'and without application options configured' do
        let(:resp1) { build_conn(:one_option).get('/success') }

        it 'has only subclass defaults' do
          expect(Faraday::Middleware.default_options).to eq(Faraday::Middleware::DEFAULT_OPTIONS)
          expect(FaradayMiddlewareSubclasses::SubclassNoOptions.default_options).to eq({ its_magic: false })
          expect(FaradayMiddlewareSubclasses::SubclassOneOption.default_options).to eq({ its_magic: false, some_other_option: false })
          expect(FaradayMiddlewareSubclasses::SubclassTwoOptions.default_options).to eq({ its_magic: false, some_option: true, some_other_option: false })
        end

        it { expect(resp1.body).to eq('ok') }
      end

      context "and with two applications' options changed" do
        let(:resp1) { build_conn(:one_option).get('/success') }
        let(:resp2) { build_conn(:two_options).get('/success') }

        before(:each) do
          FaradayMiddlewareSubclasses::SubclassOneOption.default_options = { some_other_option: true }
          FaradayMiddlewareSubclasses::SubclassTwoOptions.default_options = { some_option: false }
        end

        it 'updates subclasses and parent independent of each other' do
          expect(Faraday::Middleware.default_options).to eq(Faraday::Middleware::DEFAULT_OPTIONS)
          expect(FaradayMiddlewareSubclasses::SubclassNoOptions.default_options).to eq({ its_magic: false })
          expect(FaradayMiddlewareSubclasses::SubclassOneOption.default_options).to eq({ its_magic: false, some_other_option: true })
          expect(FaradayMiddlewareSubclasses::SubclassTwoOptions.default_options).to eq({ its_magic: false, some_option: false, some_other_option: false })
        end

        it { expect(resp1.body).to eq('ok') }
        it { expect(resp2.body).to eq('ok') }
      end
    end

    describe 'default_options input validation' do
      include_context 'reset @default_options'

      it 'raises error if Faraday::Middleware option does not exist' do
        expect { Faraday::Middleware.default_options = { something_special: true } }.to raise_error(Faraday::InitializationError) do |e|
          expect(e.message).to eq('Invalid options provided. Keys not found in Faraday::Middleware::DEFAULT_OPTIONS: something_special')
        end
      end

      it 'raises error if subclass option does not exist' do
        expect { subclass_one_option.default_options = { this_is_a_typo: true } }.to raise_error(Faraday::InitializationError) do |e|
          expect(e.message).to eq('Invalid options provided. Keys not found in FaradayMiddlewareSubclasses::SubclassOneOption::DEFAULT_OPTIONS: this_is_a_typo')
        end
      end
    end
  end
end
