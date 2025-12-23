require 'spec_helper'

describe ReverseMarkdown do

  let(:input)    { File.read('spec/assets/lists.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to match /\n- unordered list entry\n/ }
  it { is_expected.to match /\n- unordered list entry 2\n/ }
  it { is_expected.to match /\n1. ordered list entry\n/ }
  it { is_expected.to match /\n2. ordered list entry 2\n/ }
  it { is_expected.to match /\n1. list entry 1st hierarchy\n/ }
  it { is_expected.to match /\n {2}- nested unsorted list entry\n/ }
  it { is_expected.to match /\n {4}1. deep nested list entry\n/ }

  context "nested list with no whitespace" do
    it { is_expected.to match /\n- item a\n/ }
    it { is_expected.to match /\n- item b\n/ }
    it { is_expected.to match /\n {2}- item bb\n/ }
    it { is_expected.to match /\n {2}- item bc\n/ }
  end

  context "nested list with lots of whitespace" do
    it { is_expected.to match /\n- item wa \n/ }
    it { is_expected.to match /\n- item wb \n/ }
    it { is_expected.to match /\n  - item wbb \n/ }
    it { is_expected.to match /\n  - item wbc \n/ }
  end

  context "lists containing links" do
    it { is_expected.to match /\n- \[1 Basic concepts\]\(Basic_concepts\)\n/ }
    it { is_expected.to match /\n- \[2 History of the idea\]\(History_of_the_idea\)\n/ }
    it { is_expected.to match /\n- \[3 Intelligence explosion\]\(Intelligence_explosion\)\n/ }
  end

  context "lists containing embedded <p> tags" do
    it { is_expected.to match /\n- I want to have a party at my house!\n/ }
    it { is_expected.to match /\n- I don't want to cleanup after the party!\n/ }
  end

  context "list item containing multiple <p> tags" do
    xit { is_expected.to match /\n- li 1, p 1\n\n- li 1, p 2\n/ }
  end

  context 'it produces correct numbering' do
    it { is_expected.to include "1. one" }
    it { is_expected.to include "  1. one one" }
    it { is_expected.to include "  2. one two" }
    it { is_expected.to include "2. two" }
    it { is_expected.to include "  1. two one" }
    it { is_expected.to include "    1. two one one" }
    it { is_expected.to include "    2. two one two" }
    it { is_expected.to include "  2. two two" }
    it { is_expected.to include "3. three" }
  end

  context "properly embeds a nested list between adjacent list items" do
    it { is_expected.to match /\n- alpha\n/ }
    it { is_expected.to match /\n- bravo/ }
    it { is_expected.to match /\n  - bravo alpha\n/ }
    it { is_expected.to match /\n  - bravo bravo/ }
    it { is_expected.to match /\n    - bravo bravo alpha/ }
    it { is_expected.to match /\n- charlie\n/ }
    it { is_expected.to match /\n- delta\n/ }
  end

end
