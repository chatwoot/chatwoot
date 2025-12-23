require 'spec_helper'

describe ReverseMarkdown::Config do
  describe '#with' do
    let(:config) { ReverseMarkdown.config }

    it 'takes additional options into account' do
      config.with(github_flavored: :foobar) do
        expect(ReverseMarkdown.config.github_flavored).to eq :foobar
      end
    end

    it 'returns the result of a given block' do
      expect(config.with { :something }).to eq :something
    end

    it 'resets to original settings afterwards' do
      config.github_flavored = :foo
      config.with(github_flavored: :bar) do
        expect(ReverseMarkdown.config.github_flavored).to eq :bar
      end
      expect(ReverseMarkdown.config.github_flavored).to eq :foo
    end

  end
end
