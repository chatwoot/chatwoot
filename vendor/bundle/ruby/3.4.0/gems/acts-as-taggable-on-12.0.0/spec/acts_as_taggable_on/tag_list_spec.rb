# -*- encoding : utf-8 -*-

require 'spec_helper'

describe ActsAsTaggableOn::TagList do
  let(:tag_list) { ActsAsTaggableOn::TagList.new('awesome', 'radical') }
  let(:another_tag_list) { ActsAsTaggableOn::TagList.new('awesome','crazy', 'alien') }

  it { should be_kind_of Array }



  describe '#add' do
    it 'should be able to be add a new tag word' do
      tag_list.add('cool')
      expect(tag_list.include?('cool')).to be_truthy
    end

    it 'should be able to add delimited lists of words' do
      tag_list.add('cool, wicked', parse: true)
      expect(tag_list).to include('cool', 'wicked')
    end

    it 'should be able to add delimited list of words with quoted delimiters' do
      tag_list.add("'cool, wicked', \"really cool, really wicked\"", parse: true)
      expect(tag_list).to include('cool, wicked', 'really cool, really wicked')
    end

    it 'should be able to handle other uses of quotation marks correctly' do
      tag_list.add("john's cool car, mary's wicked toy", parse: true)
      expect(tag_list).to include("john's cool car", "mary's wicked toy")
    end

    it 'should be able to add an array of words' do
      tag_list.add(%w(cool wicked), parse: true)
      expect(tag_list).to include('cool', 'wicked')
    end

    it 'should quote escape tags with commas in them' do
      tag_list.add('cool', 'rad,bodacious')
      expect(tag_list.to_s).to eq("awesome, radical, cool, \"rad,bodacious\"")
    end

  end

  describe '#remove' do
    it 'should be able to remove words' do
      tag_list.remove('awesome')
      expect(tag_list).to_not include('awesome')
    end

    it 'should be able to remove delimited lists of words' do
      tag_list.remove('awesome, radical', parse: true)
      expect(tag_list).to be_empty
    end

    it 'should be able to remove an array of words' do
      tag_list.remove(%w(awesome radical), parse: true)
      expect(tag_list).to be_empty
    end
  end

  describe '#+' do
    it 'should not have duplicate tags' do
      new_tag_list = tag_list + another_tag_list
      expect(tag_list).to eq(%w[awesome radical])
      expect(another_tag_list).to eq(%w[awesome crazy alien])
      expect(new_tag_list).to eq(%w[awesome radical crazy alien])
    end

    it 'should have class : ActsAsTaggableOn::TagList' do
      new_tag_list = tag_list + another_tag_list
      expect(new_tag_list.class).to eq(ActsAsTaggableOn::TagList)
    end
  end

  describe '#concat' do
    it 'should not have duplicate tags' do
      expect(tag_list.concat(another_tag_list)).to eq(%w[awesome radical crazy alien])
    end

    it 'should have class : ActsAsTaggableOn::TagList' do
      new_tag_list = tag_list.concat(another_tag_list)
      expect(new_tag_list.class).to eq(ActsAsTaggableOn::TagList)
    end

    context 'without duplicates' do
      let(:arr) { ['crazy', 'alien'] }
      let(:another_tag_list) { ActsAsTaggableOn::TagList.new(*arr) }
      it 'adds other list' do
        expect(tag_list.concat(another_tag_list)).to eq(%w[awesome radical crazy alien])
      end

      it 'adds other array' do
        expect(tag_list.concat(arr)).to eq(%w[awesome radical crazy alien])
      end
    end
  end

  describe '#to_s' do
    it 'should give a delimited list of words when converted to string' do
      expect(tag_list.to_s).to eq('awesome, radical')
    end

    it 'should be able to call to_s on a frozen tag list' do
      tag_list.freeze
      expect { tag_list.add('cool', 'rad,bodacious') }.to raise_error(RuntimeError)
      expect { tag_list.to_s }.to_not raise_error
    end
  end

  describe 'cleaning' do
    it 'should parameterize if force_parameterize is set to true' do
      ActsAsTaggableOn.force_parameterize = true
      tag_list = ActsAsTaggableOn::TagList.new('awesome()', 'radical)(cc')

      expect(tag_list.to_s).to eq('awesome, radical-cc')
      ActsAsTaggableOn.force_parameterize = false
    end

    it 'should lowercase if force_lowercase is set to true' do
      ActsAsTaggableOn.force_lowercase = true

      tag_list = ActsAsTaggableOn::TagList.new('aweSomE', 'RaDicaL', 'Entrée')
      expect(tag_list.to_s).to eq('awesome, radical, entrée')

      ActsAsTaggableOn.force_lowercase = false
    end

    it 'should ignore case when removing duplicates if strict_case_match is false' do
      tag_list = ActsAsTaggableOn::TagList.new('Junglist', 'JUNGLIST', 'Junglist', 'Massive', 'MASSIVE', 'MASSIVE')

      expect(tag_list.to_s).to eq('Junglist, Massive')
    end

    it 'should not ignore case when removing duplicates if strict_case_match is true' do
      ActsAsTaggableOn.strict_case_match = true
      tag_list = ActsAsTaggableOn::TagList.new('Junglist', 'JUNGLIST', 'Junglist', 'Massive', 'MASSIVE', 'MASSIVE')

      expect(tag_list.to_s).to eq('Junglist, JUNGLIST, Massive, MASSIVE')
      ActsAsTaggableOn.strict_case_match = false
    end
  end

  describe 'custom parser' do
    let(:parser)       { double(parse: %w(cool wicked)) }
    let(:parser_class) { stub_const('MyParser', Class) }

    it 'should use a the default parser if none is set as parameter' do
      allow(ActsAsTaggableOn.default_parser).to receive(:new).and_return(parser)
      ActsAsTaggableOn::TagList.new('cool, wicked', parse: true)

      expect(parser).to have_received(:parse)
    end

    it 'should use the custom parser passed as parameter' do
      allow(parser_class).to receive(:new).and_return(parser)

      ActsAsTaggableOn::TagList.new('cool, wicked', parser: parser_class)

      expect(parser).to have_received(:parse)
    end

    it 'should use the parser set as attribute' do
      allow(parser_class).to receive(:new).with('new, tag').and_return(parser)

      tag_list = ActsAsTaggableOn::TagList.new('example')
      tag_list.parser = parser_class
      tag_list.add('new, tag', parse: true)

      expect(parser).to have_received(:parse)
    end
  end


end
