require 'rails_helper'

describe Whatsapp::TemplateFormatterService do
  describe '.format_status_from_meta' do
    it 'converts APPROVED to approved' do
      expect(described_class.format_status_from_meta('APPROVED')).to eq('approved')
    end

    it 'converts PENDING to pending' do
      expect(described_class.format_status_from_meta('PENDING')).to eq('pending')
    end

    it 'converts REJECTED to rejected' do
      expect(described_class.format_status_from_meta('REJECTED')).to eq('rejected')
    end

    it 'converts unknown status to draft' do
      expect(described_class.format_status_from_meta('UNKNOWN')).to eq('draft')
      expect(described_class.format_status_from_meta(nil)).to eq('draft')
      expect(described_class.format_status_from_meta('')).to eq('draft')
    end
  end

  describe '.format_category_from_meta' do
    it 'converts MARKETING to marketing' do
      expect(described_class.format_category_from_meta('MARKETING')).to eq('marketing')
    end

    it 'converts AUTHENTICATION to authentication' do
      expect(described_class.format_category_from_meta('AUTHENTICATION')).to eq('authentication')
    end

    it 'converts UTILITY to utility' do
      expect(described_class.format_category_from_meta('UTILITY')).to eq('utility')
    end

    it 'converts unknown category to utility' do
      expect(described_class.format_category_from_meta('UNKNOWN')).to eq('utility')
      expect(described_class.format_category_from_meta(nil)).to eq('utility')
      expect(described_class.format_category_from_meta('')).to eq('utility')
    end
  end

  describe '.format_parameter_format_from_meta' do
    it 'converts NAMED to named' do
      expect(described_class.format_parameter_format_from_meta('NAMED')).to eq('named')
    end

    it 'converts POSITIONAL to positional' do
      expect(described_class.format_parameter_format_from_meta('POSITIONAL')).to eq('positional')
    end

    it 'returns nil for unknown format' do
      expect(described_class.format_parameter_format_from_meta('UNKNOWN')).to be_nil
      expect(described_class.format_parameter_format_from_meta(nil)).to be_nil
      expect(described_class.format_parameter_format_from_meta('')).to be_nil
    end
  end

  describe '.format_status_for_meta' do
    it 'converts approved to APPROVED' do
      expect(described_class.format_status_for_meta('approved')).to eq('APPROVED')
    end

    it 'converts rejected to REJECTED' do
      expect(described_class.format_status_for_meta('rejected')).to eq('REJECTED')
    end

    it 'converts pending to PENDING' do
      expect(described_class.format_status_for_meta('pending')).to eq('PENDING')
    end

    it 'converts unknown status to PENDING' do
      expect(described_class.format_status_for_meta('draft')).to eq('PENDING')
      expect(described_class.format_status_for_meta('unknown')).to eq('PENDING')
      expect(described_class.format_status_for_meta(nil)).to eq('PENDING')
      expect(described_class.format_status_for_meta('')).to eq('PENDING')
    end
  end

  describe '.format_category_for_meta' do
    it 'converts marketing to MARKETING' do
      expect(described_class.format_category_for_meta('marketing')).to eq('MARKETING')
    end

    it 'converts authentication to AUTHENTICATION' do
      expect(described_class.format_category_for_meta('authentication')).to eq('AUTHENTICATION')
    end

    it 'converts utility to UTILITY' do
      expect(described_class.format_category_for_meta('utility')).to eq('UTILITY')
    end

    it 'converts unknown category to UTILITY' do
      expect(described_class.format_category_for_meta('unknown')).to eq('UTILITY')
      expect(described_class.format_category_for_meta(nil)).to eq('UTILITY')
      expect(described_class.format_category_for_meta('')).to eq('UTILITY')
    end
  end

  describe '.format_parameter_format_for_meta' do
    it 'converts named to NAMED' do
      expect(described_class.format_parameter_format_for_meta('named')).to eq('NAMED')
    end

    it 'converts positional to POSITIONAL' do
      expect(described_class.format_parameter_format_for_meta('positional')).to eq('POSITIONAL')
    end

    it 'returns nil for unknown format' do
      expect(described_class.format_parameter_format_for_meta('unknown')).to be_nil
      expect(described_class.format_parameter_format_for_meta(nil)).to be_nil
      expect(described_class.format_parameter_format_for_meta('')).to be_nil
    end
  end
end
