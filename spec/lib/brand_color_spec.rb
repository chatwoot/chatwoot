# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrandColor do
  describe '.surface' do
    it 'keeps a configured colour as it is' do
      expect(described_class.surface('#11D135')).to eq '#11D135'
    end

    it 'expands the shorthand form' do
      expect(described_class.surface('#0af')).to eq '#00AAFF'
    end

    it 'falls back to the default when the value is missing or not a colour' do
      expect(described_class.surface(nil)).to eq described_class::DEFAULT
      expect(described_class.surface('rebeccapurple')).to eq described_class::DEFAULT
    end
  end

  describe '.on_light' do
    it 'darkens a brand colour that would be unreadable on the white card' do
      # #11D135 sits at 2.06:1 against white, well under AA.
      expect(described_class.on_light('#11D135')).to eq '#0B8822'
    end

    it 'reaches AA contrast for every colour it returns' do
      ['#11D135', '#FFEE00', '#00CFCF', '#1F93FF', '#FFFFFF'].each do |hex|
        expect(contrast_with_white(described_class.on_light(hex))).to be >= described_class::MIN_CONTRAST
      end
    end

    it 'leaves a colour that already clears AA alone' do
      expect(described_class.on_light('#000000')).to eq '#000000'
    end
  end

  def contrast_with_white(hex)
    linear = hex[1..].scan(/\h{2}/).map do |pair|
      value = pair.to_i(16) / 255.0
      value <= 0.03928 ? value / 12.92 : (((value + 0.055) / 1.055)**2.4)
    end
    luminance = (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2])
    1.05 / (luminance + 0.05)
  end
end
