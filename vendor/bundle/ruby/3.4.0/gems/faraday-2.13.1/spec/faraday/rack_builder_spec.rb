# frozen_string_literal: true

RSpec.describe Faraday::RackBuilder do
  # mock handler classes
  (Handler = Struct.new(:app)).class_eval do
    def call(env)
      env[:request_headers]['X-Middleware'] ||= ''
      env[:request_headers]['X-Middleware'] += ":#{self.class.name.split('::').last}"
      app.call(env)
    end
  end

  class Apple < Handler
  end

  class Orange < Handler
  end

  class Banana < Handler
  end

  subject { conn.builder }
  before { Faraday.default_adapter = :test }
  after { Faraday.default_adapter = nil }

  context 'with default stack' do
    let(:conn) { Faraday::Connection.new }

    it { expect(subject[0]).to eq(Faraday::Request.lookup_middleware(:url_encoded)) }
    it { expect(subject.adapter).to eq(Faraday::Adapter.lookup_middleware(Faraday.default_adapter)) }
  end

  context 'with custom empty block' do
    let(:conn) { Faraday::Connection.new {} }

    it { expect(subject[0]).to be_nil }
    it { expect(subject.adapter).to eq(Faraday::Adapter.lookup_middleware(Faraday.default_adapter)) }
  end

  context 'with custom adapter only' do
    let(:conn) do
      Faraday::Connection.new do |builder|
        builder.adapter :test do |stub|
          stub.get('/') { |_| [200, {}, ''] }
        end
      end
    end

    it { expect(subject[0]).to be_nil }
    it { expect(subject.adapter).to eq(Faraday::Adapter.lookup_middleware(:test)) }
  end

  context 'with custom handler and adapter' do
    let(:conn) do
      Faraday::Connection.new do |builder|
        builder.use Apple
        builder.adapter :test do |stub|
          stub.get('/') { |_| [200, {}, ''] }
        end
      end
    end

    it 'locks the stack after making a request' do
      expect(subject.locked?).to be_falsey
      conn.get('/')
      expect(subject.locked?).to be_truthy
      expect { subject.use(Orange) }.to raise_error(Faraday::RackBuilder::StackLocked)
    end

    it 'dup stack is unlocked' do
      expect(subject.locked?).to be_falsey
      subject.lock!
      expect(subject.locked?).to be_truthy
      dup = subject.dup
      expect(dup).to eq(subject)
      expect(dup.locked?).to be_falsey
    end

    it 'allows to compare handlers' do
      expect(subject.handlers.first).to eq(Faraday::RackBuilder::Handler.new(Apple))
    end
  end

  context 'when having a single handler' do
    let(:conn) { Faraday::Connection.new {} }

    before { subject.use(Apple) }

    it { expect(subject.handlers).to eq([Apple]) }

    it 'allows use' do
      subject.use(Orange)
      expect(subject.handlers).to eq([Apple, Orange])
    end

    it 'allows insert_before' do
      subject.insert_before(Apple, Orange)
      expect(subject.handlers).to eq([Orange, Apple])
    end

    it 'allows insert_after' do
      subject.insert_after(Apple, Orange)
      expect(subject.handlers).to eq([Apple, Orange])
    end

    it 'raises an error trying to use an unregistered symbol' do
      expect { subject.use(:apple) }.to raise_error(Faraday::Error) do |err|
        expect(err.message).to eq(':apple is not registered on Faraday::Middleware')
      end
    end
  end

  context 'when having two handlers' do
    let(:conn) { Faraday::Connection.new {} }

    before do
      subject.use(Apple)
      subject.use(Orange)
    end

    it 'allows insert_before' do
      subject.insert_before(Orange, Banana)
      expect(subject.handlers).to eq([Apple, Banana, Orange])
    end

    it 'allows insert_after' do
      subject.insert_after(Apple, Banana)
      expect(subject.handlers).to eq([Apple, Banana, Orange])
    end

    it 'allows to swap handlers' do
      subject.swap(Apple, Banana)
      expect(subject.handlers).to eq([Banana, Orange])
    end

    it 'allows to delete a handler' do
      subject.delete(Apple)
      expect(subject.handlers).to eq([Orange])
    end
  end

  context 'when adapter is added with named options' do
    after { Faraday.default_adapter_options = {} }
    let(:conn) { Faraday::Connection.new {} }

    let(:cat_adapter) do
      Class.new(Faraday::Adapter) do
        attr_accessor :name

        def initialize(app, name:)
          super(app)
          @name = name
        end
      end
    end

    let(:cat) { subject.adapter.build }

    it 'adds a handler to construct adapter with named options' do
      Faraday.default_adapter = cat_adapter
      Faraday.default_adapter_options = { name: 'Chloe' }
      expect { cat }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(cat.name).to eq 'Chloe'
    end
  end

  context 'when middleware is added with named arguments' do
    let(:conn) { Faraday::Connection.new {} }

    let(:dog_middleware) do
      Class.new(Faraday::Middleware) do
        attr_accessor :name

        def initialize(app, name:)
          super(app)
          @name = name
        end
      end
    end
    let(:dog) do
      subject.handlers.find { |handler| handler == dog_middleware }.build
    end

    it 'adds a handler to construct middleware with options passed to use' do
      subject.use dog_middleware, name: 'Rex'
      expect { dog }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(dog.name).to eq('Rex')
    end
  end

  context 'when a middleware is added with named arguments' do
    let(:conn) { Faraday::Connection.new {} }

    let(:cat_request) do
      Class.new(Faraday::Middleware) do
        attr_accessor :name

        def initialize(app, name:)
          super(app)
          @name = name
        end
      end
    end
    let(:cat) do
      subject.handlers.find { |handler| handler == cat_request }.build
    end

    it 'adds a handler to construct request adapter with options passed to request' do
      Faraday::Request.register_middleware cat_request: cat_request
      subject.request :cat_request, name: 'Felix'
      expect { cat }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(cat.name).to eq('Felix')
    end
  end

  context 'when a middleware is added with named arguments' do
    let(:conn) { Faraday::Connection.new {} }

    let(:fish_response) do
      Class.new(Faraday::Middleware) do
        attr_accessor :name

        def initialize(app, name:)
          super(app)
          @name = name
        end
      end
    end
    let(:fish) do
      subject.handlers.find { |handler| handler == fish_response }.build
    end

    it 'adds a handler to construct response adapter with options passed to response' do
      Faraday::Response.register_middleware fish_response: fish_response
      subject.response :fish_response, name: 'Bubbles'
      expect { fish }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(fish.name).to eq('Bubbles')
    end
  end

  context 'when a plain adapter is added with named arguments' do
    let(:conn) { Faraday::Connection.new {} }

    let(:rabbit_adapter) do
      Class.new(Faraday::Adapter) do
        attr_accessor :name

        def initialize(app, name:)
          super(app)
          @name = name
        end
      end
    end
    let(:rabbit) do
      subject.adapter.build
    end

    it 'adds a handler to construct adapter with options passed to adapter' do
      Faraday::Adapter.register_middleware rabbit_adapter: rabbit_adapter
      subject.adapter :rabbit_adapter, name: 'Thumper'
      expect { rabbit }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(rabbit.name).to eq('Thumper')
    end
  end

  context 'when handlers are directly added or updated' do
    let(:conn) { Faraday::Connection.new {} }

    let(:rock_handler) do
      Class.new do
        attr_accessor :name

        def initialize(_app, name:)
          @name = name
        end
      end
    end
    let(:rock) do
      subject.handlers.find { |handler| handler == rock_handler }.build
    end

    it 'adds a handler to construct adapter with options passed to insert' do
      subject.insert 0, rock_handler, name: 'Stony'
      expect { rock }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(rock.name).to eq('Stony')
    end

    it 'adds a handler with options passed to insert_after' do
      subject.insert_after 0, rock_handler, name: 'Rocky'
      expect { rock }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(rock.name).to eq('Rocky')
    end

    it 'adds a handler with options passed to swap' do
      subject.insert 0, rock_handler, name: 'Flint'
      subject.swap 0, rock_handler, name: 'Chert'
      expect { rock }.to_not output(
        /warning: Using the last argument as keyword parameters is deprecated/
      ).to_stderr
      expect(rock.name).to eq('Chert')
    end
  end
end
