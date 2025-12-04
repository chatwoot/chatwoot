# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::PromptRenderer do
  describe '.render' do
    let(:template_name) { 'test_template' }
    let(:template_content) { 'Hello {{ name }}, you have {{ count }} messages.' }
    let(:template_path) { Rails.root.join('extended', 'lib', 'captain', 'prompts', "#{template_name}.liquid") }

    before do
      allow(File).to receive(:exist?).with(template_path).and_return(true)
      allow(File).to receive(:read).with(template_path).and_return(template_content)
    end

    it 'renders a template with provided context' do
      context = { name: 'John', count: 5 }
      result = described_class.render(template_name, context)

      expect(result).to eq('Hello John, you have 5 messages.')
    end

    it 'handles symbol keys in context' do
      context = { name: 'Alice', count: 3 }
      result = described_class.render(template_name, context)

      expect(result).to eq('Hello Alice, you have 3 messages.')
    end

    it 'handles string keys in context' do
      context = { 'name' => 'Bob', 'count' => 7 }
      result = described_class.render(template_name, context)

      expect(result).to eq('Hello Bob, you have 7 messages.')
    end

    it 'handles nested context' do
      nested_template = 'User: {{ user.name }}, Email: {{ user.email }}'
      allow(File).to receive(:read).with(template_path).and_return(nested_template)

      context = { user: { name: 'Charlie', email: 'charlie@example.com' } }
      result = described_class.render(template_name, context)

      expect(result).to eq('User: Charlie, Email: charlie@example.com')
    end

    it 'raises error when template does not exist' do
      allow(File).to receive(:exist?).with(template_path).and_return(false)

      expect { described_class.render(template_name, {}) }.to raise_error(/Template not found/)
    end

    it 'handles empty context' do
      simple_template = 'Static content'
      allow(File).to receive(:read).with(template_path).and_return(simple_template)

      result = described_class.render(template_name, {})

      expect(result).to eq('Static content')
    end
  end
end
