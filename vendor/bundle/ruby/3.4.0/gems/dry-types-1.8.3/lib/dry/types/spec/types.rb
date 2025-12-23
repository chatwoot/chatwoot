# frozen_string_literal: true

RSpec.shared_examples_for "Dry::Types::Nominal without primitive" do
  def be_boolean
    satisfy { |x| x == true || x == false }
  end

  describe "#constrained?" do
    it "returns a boolean value" do
      expect(type.constrained?).to be_boolean
    end
  end

  describe "#default?" do
    it "returns a boolean value" do
      expect(type.default?).to be_boolean
    end
  end

  describe "#valid?" do
    it "returns a boolean value" do
      expect(type.valid?(1)).to be_boolean
    end
  end

  describe "#eql?" do
    it "has #eql? defined" do
      expect(type).to eql(type)
    end
  end

  describe "#==" do
    it "has #== defined" do
      expect(type).to eql(type)
    end
  end

  describe "#optional?" do
    it "returns a boolean value" do
      expect(type.optional?).to be_boolean
    end
  end

  describe "#to_s" do
    it "returns a custom string representation" do
      expect(type.to_s).to start_with("#<Dry::Types") if type.class.name.start_with?("Dry::Types")
    end
  end

  describe "#to_proc" do
    subject(:callable) { type.to_proc }

    it "converts a type to a proc" do
      expect(callable).to be_a(Proc)
    end
  end
end

RSpec.shared_examples_for "Dry::Types::Nominal#meta" do
  describe "#meta" do
    it "allows setting meta information" do
      with_meta = type.meta(foo: :bar).meta(baz: "1")

      expect(with_meta).to be_instance_of(type.class)
      expect(with_meta.meta).to eql(foo: :bar, baz: "1")
    end

    it "equalizes on empty meta" do
      expect(type).to eql(type.meta({}))
    end

    it "equalizes on filled meta" do
      expect(type).to_not eql(type.meta(i_am: "different"))
    end

    it "is locally immutable" do
      expect(type.meta).to be_a Hash
      expect(type.meta).to be_frozen
      expect(type.meta).not_to have_key :immutable_test
      derived = type.meta(immutable_test: 1)
      expect(derived.meta).to be_frozen
      expect(derived.meta).to eql(immutable_test: 1)
      expect(type.meta).not_to have_key :immutable_test
    end
  end

  describe "#pristine" do
    it "erases meta" do
      expect(type.meta(foo: :bar).pristine).to eql(type)
    end
  end
end

RSpec.shared_examples_for Dry::Types::Nominal do
  it_behaves_like "Dry::Types::Nominal without primitive"

  describe "#primitive" do
    it "returns a class" do
      expect(type.primitive).to be_instance_of(Class)
    end
  end

  describe "#constructor" do
    it "returns a constructor" do
      constructor = type.constructor(&:to_s)

      expect(constructor).to be_a(Dry::Types::Type)
    end
  end
end

RSpec.shared_examples_for "a constrained type" do |options = {inputs: Object.new}|
  inputs = options[:inputs]

  let(:fallback) { Object.new }

  describe "#call" do
    it "yields a block on failure" do
      Array(inputs).each do |input|
        expect(type.(input) { fallback }).to be(fallback)
      end
    end

    it "throws an error on invalid input" do
      Array(inputs).each do |input|
        expect { type.(input) }.to raise_error(Dry::Types::CoercionError)
      end
    end
  end

  describe "#constructor" do
    let(:wrapping_constructor) do
      type.constructor { |input, type| type.(input) { fallback } }
    end

    it "can be wrapped" do
      Array(inputs).each do |input|
        expect(wrapping_constructor.(input)).to be(fallback)
      end
    end
  end
end

RSpec.shared_examples_for "a nominal type" do |inputs: Object.new|
  describe "#call" do
    it "always returns the input back" do
      Array(inputs).each do |input|
        expect(type.(input) { raise }).to be(input)
        expect(type.(input)).to be(input)
      end
    end
  end
end

RSpec.shared_examples_for "a composable constructor" do
  describe "#constructor" do
    it "has aliases for composition" do
      expect(type.method(:append)).to eql(type.method(:constructor))
      expect(type.method(:prepend)).to eql(type.method(:constructor))
      expect(type.method(:<<)).to eql(type.method(:constructor))
      expect(type.method(:>>)).to eql(type.method(:constructor))
    end
  end
end
