# frozen_string_literal: true

RSpec.describe Faraday::Options do
  SubOptions = Class.new(Faraday::Options.new(:sub_a, :sub_b))
  ParentOptions = Faraday::Options.new(:a, :b, :c) do
    options c: SubOptions
  end

  describe '#merge' do
    it 'merges options with hashes' do
      options = ParentOptions.new(1)
      expect(options.a).to eq(1)
      expect(options.b).to be_nil

      dup = options.merge a: 2, b: 3
      expect(dup.a).to eq(2)
      expect(dup.b).to eq(3)
      expect(options.a).to eq(1)
      expect(options.b).to be_nil
    end

    it 'deeply merges two options' do
      sub_opts1 = SubOptions.from(sub_a: 3)
      sub_opts2 = SubOptions.from(sub_b: 4)
      opt1      = ParentOptions.from(a: 1, c: sub_opts1)
      opt2      = ParentOptions.from(b: 2, c: sub_opts2)

      merged = opt1.merge(opt2)

      expected_sub_opts = SubOptions.from(sub_a: 3, sub_b: 4)
      expected          = ParentOptions.from(a: 1, b: 2, c: expected_sub_opts)
      expect(merged).to eq(expected)
    end

    it 'deeply merges options with hashes' do
      sub_opts1 = SubOptions.from(sub_a: 3)
      sub_opts2 = { sub_b: 4 }
      opt1      = ParentOptions.from(a: 1, c: sub_opts1)
      opt2      = { b: 2, c: sub_opts2 }

      merged = opt1.merge(opt2)

      expected_sub_opts = SubOptions.from(sub_a: 3, sub_b: 4)
      expected          = ParentOptions.from(a: 1, b: 2, c: expected_sub_opts)
      expect(merged).to eq(expected)
    end

    it 'deeply merges options with nil' do
      sub_opts = SubOptions.new(3, 4)
      options  = ParentOptions.new(1, 2, sub_opts)
      expect(options.a).to eq(1)
      expect(options.b).to eq(2)
      expect(options.c.sub_a).to eq(3)
      expect(options.c.sub_b).to eq(4)

      options2 = ParentOptions.from(b: 5, c: nil)

      merged = options.merge(options2)

      expect(merged.b).to eq(5)
      expect(merged.c).to eq(sub_opts)
    end

    it 'deeply merges options with options having nil sub-options' do
      options = ParentOptions.from(a: 1)

      sub_opts = SubOptions.new(3, 4)
      options2 = ParentOptions.from(b: 2, c: sub_opts)

      expect(options.a).to eq(1)
      expect(options2.b).to eq(2)
      expect(options2.c.sub_a).to eq(3)
      expect(options2.c.sub_b).to eq(4)

      merged = options.merge(options2)

      expect(merged.c).to eq(sub_opts)
    end

    describe '#dup' do
      it 'duplicate options but not sub-options' do
        sub_opts = SubOptions.from(sub_a: 3)
        opts     = ParentOptions.from(b: 1, c: sub_opts)

        duped         = opts.dup
        duped.b       = 2
        duped.c.sub_a = 4

        expect(opts.b).to eq(1)
        expect(opts.c.sub_a).to eq(4)
      end
    end

    describe '#deep_dup' do
      it 'duplicate options and also suboptions' do
        sub_opts = SubOptions.from(sub_a: 3)
        opts     = ParentOptions.from(b: 1, c: sub_opts)

        duped         = opts.deep_dup
        duped.b       = 2
        duped.c.sub_a = 4

        expect(opts.b).to eq(1)
        expect(opts.c.sub_a).to eq(3)
      end
    end

    describe '#clear' do
      it 'clears the options' do
        options = SubOptions.new(1)
        expect(options.empty?).not_to be_truthy
        options.clear
        expect(options.empty?).to be_truthy
      end
    end

    describe '#empty?' do
      it 'returns true only if all options are nil' do
        options = SubOptions.new
        expect(options.empty?).to be_truthy
        options.sub_a = 1
        expect(options.empty?).not_to be_truthy
        options.delete(:sub_a)
        expect(options.empty?).to be_truthy
      end
    end

    describe '#each_key' do
      it 'allows to iterate through keys' do
        options = ParentOptions.new(1, 2, 3)
        enum    = options.each_key
        expect(enum.next.to_sym).to eq(:a)
        expect(enum.next.to_sym).to eq(:b)
        expect(enum.next.to_sym).to eq(:c)
      end
    end

    describe '#key?' do
      it 'returns true if the key exists and is not nil' do
        options = SubOptions.new
        expect(options.key?(:sub_a)).not_to be_truthy
        options.sub_a = 1
        expect(options.key?(:sub_a)).to be_truthy
      end
    end

    describe '#each_value' do
      it 'allows to iterate through values' do
        options = ParentOptions.new(1, 2, 3)
        enum    = options.each_value
        expect(enum.next).to eq(1)
        expect(enum.next).to eq(2)
        expect(enum.next).to eq(3)
      end
    end

    describe '#value?' do
      it 'returns true if any key has that value' do
        options = SubOptions.new
        expect(options.value?(1)).not_to be_truthy
        options.sub_a = 1
        expect(options.value?(1)).to be_truthy
      end
    end

    describe '#update' do
      it 'updates options from hashes' do
        options = ParentOptions.new(1)
        expect(options.a).to eq(1)
        expect(options.b).to be_nil

        updated = options.update a: 2, b: 3
        expect(options.a).to eq(2)
        expect(options.b).to eq(3)
        expect(updated).to eq(options)
      end
    end

    describe '#delete' do
      it 'allows to remove value for key' do
        options = ParentOptions.new(1)
        expect(options.a).to eq(1)
        expect(options.delete(:a)).to eq(1)
        expect(options.a).to be_nil
      end
    end

    describe '#from' do
      it { expect { ParentOptions.from invalid: 1 }.to raise_error(NoMethodError) }

      it 'works with options' do
        options = ParentOptions.new(1)

        value = ParentOptions.from(options)
        expect(value.a).to eq(1)
        expect(value.b).to be_nil
      end

      it 'works with options with sub object' do
        sub     = SubOptions.new(1)
        options = ParentOptions.from a: 1, c: sub
        expect(options).to be_a_kind_of(ParentOptions)
        expect(options.a).to eq(1)
        expect(options.b).to be_nil
        expect(options.c).to be_a_kind_of(SubOptions)
        expect(options.c.sub_a).to eq(1)
      end

      it 'works with hash' do
        options = ParentOptions.from a: 1
        expect(options).to be_a_kind_of(ParentOptions)
        expect(options.a).to eq(1)
        expect(options.b).to be_nil
      end

      it 'works with hash with sub object' do
        options = ParentOptions.from a: 1, c: { sub_a: 1 }
        expect(options).to be_a_kind_of(ParentOptions)
        expect(options.a).to eq(1)
        expect(options.b).to be_nil
        expect(options.c).to be_a_kind_of(SubOptions)
        expect(options.c.sub_a).to eq(1)
      end

      it 'works with deep hash' do
        hash    = { b: 1 }
        options = ParentOptions.from a: hash
        expect(options.a[:b]).to eq(1)

        hash[:b] = 2
        expect(options.a[:b]).to eq(1)

        options.a[:b] = 3
        expect(hash[:b]).to eq(2)
        expect(options.a[:b]).to eq(3)
      end

      it 'works with nil' do
        options = ParentOptions.from(nil)
        expect(options).to be_a_kind_of(ParentOptions)
        expect(options.a).to be_nil
        expect(options.b).to be_nil
      end

      it 'respects inheritance' do
        subclass = Class.new(ParentOptions)
        options  = subclass.from(c: { sub_a: 'hello' })
        expect(options.c).to be_a_kind_of(SubOptions)
        expect(options.c.sub_a).to eq('hello')
      end
    end

    describe '#memoized' do
      subject(:options_class) { Class.new(ParentOptions) }
      it 'requires block' do
        expect { options_class.memoized(:a) }.to raise_error(ArgumentError)
      end

      it 'accepts block' do
        options_class.memoized(:a) { :foo }
        expect(options_class.new.a).to eql(:foo)
      end
    end

    describe '#fetch' do
      subject { SubOptions.new }

      context 'when the fetched key has no value' do
        it 'uses falsey default' do
          expect(subject.fetch(:sub_a, false) { |_| :blah }).to be_falsey
        end

        it 'accepts block' do
          expect(subject.fetch(:sub_a) { |k| "yo #{k.inspect}" }).to eq('yo :sub_a')
        end

        it 'needs a default if key is missing' do
          expect { subject.fetch(:sub_a) }.to raise_error(Faraday::Options.fetch_error_class)
        end
      end

      context 'when the fetched key has a value' do
        before do
          subject.sub_a = 1
        end

        it 'grabs value' do
          expect(subject.fetch(:sub_a, false) { |_| :blah }).to eq(1)
        end

        it 'works with key' do
          expect(subject.fetch(:sub_a)).to eq(1)
        end
      end
    end
  end
end
