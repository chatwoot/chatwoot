require 'rails_helper'

RSpec.describe Concerns::CaptainToolsHelpers, type: :concern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Concerns::CaptainToolsHelpers

      def self.name
        'TestClass'
      end
    end
  end

  let(:test_instance) { test_class.new }

  describe 'TOOL_REFERENCE_REGEX' do
    it 'matches tool references in text' do
      text = 'Use [@Add Contact Note](tool://add_contact_note) and [Update Priority](tool://update_priority)'
      matches = text.scan(Concerns::CaptainToolsHelpers::TOOL_REFERENCE_REGEX)

      expect(matches.flatten).to eq(%w[add_contact_note update_priority])
    end

    it 'does not match invalid formats' do
      invalid_formats = [
        '<tool://invalid>',
        'tool://invalid',
        '(tool:invalid)',
        '(tool://)',
        '(tool://with/slash)',
        '(tool://add_contact_note)',
        '[@Tool](tool://)',
        '[Tool](tool://with/slash)',
        '[](tool://valid)'
      ]

      invalid_formats.each do |format|
        matches = format.scan(Concerns::CaptainToolsHelpers::TOOL_REFERENCE_REGEX)
        expect(matches).to be_empty, "Should not match: #{format}"
      end
    end
  end

  describe '.resolve_tool_class' do
    it 'resolves valid tool classes' do
      # Mock the constantize to return a class
      stub_const('Captain::Tools::AddContactNoteTool', Class.new)

      result = test_class.resolve_tool_class('add_contact_note')
      expect(result).to eq(Captain::Tools::AddContactNoteTool)
    end

    it 'returns nil for invalid tool classes' do
      result = test_class.resolve_tool_class('invalid_tool')
      expect(result).to be_nil
    end

    it 'converts snake_case to PascalCase' do
      stub_const('Captain::Tools::AddPrivateNoteTool', Class.new)

      result = test_class.resolve_tool_class('add_private_note')
      expect(result).to eq(Captain::Tools::AddPrivateNoteTool)
    end
  end

  describe '#extract_tool_ids_from_text' do
    it 'extracts tool IDs from text' do
      text = 'First [@Add Contact Note](tool://add_contact_note) then [@Update Priority](tool://update_priority)'
      result = test_instance.extract_tool_ids_from_text(text)

      expect(result).to eq(%w[add_contact_note update_priority])
    end

    it 'returns unique tool IDs' do
      text = 'Use [@Add Contact Note](tool://add_contact_note) and [@Contact Note](tool://add_contact_note) again'
      result = test_instance.extract_tool_ids_from_text(text)

      expect(result).to eq(['add_contact_note'])
    end

    it 'returns empty array for blank text' do
      expect(test_instance.extract_tool_ids_from_text('')).to eq([])
      expect(test_instance.extract_tool_ids_from_text(nil)).to eq([])
      expect(test_instance.extract_tool_ids_from_text('   ')).to eq([])
    end

    it 'returns empty array when no tools found' do
      text = 'This text has no tool references'
      result = test_instance.extract_tool_ids_from_text(text)

      expect(result).to eq([])
    end

    it 'handles complex text with multiple tools' do
      text = <<~TEXT
        Start with [@Add Contact Note](tool://add_contact_note) to document.
        Then use [@Update Priority](tool://update_priority) if needed.
        Finally [@Add Private Note](tool://add_private_note) for internal notes.
      TEXT

      result = test_instance.extract_tool_ids_from_text(text)
      expect(result).to eq(%w[add_contact_note update_priority add_private_note])
    end
  end
end
