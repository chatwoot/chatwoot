require 'rails_helper'

# the values for these test cases are based off https://github.com/ricokahler/color2k/

RSpec.describe ColorHelper do
  describe '#hex_to_rgb' do
    it 'converts a hex color to RGB' do
      pairs = [
        ['#fefce8', [254, 252, 232]],
        ['#fef9c3', [254, 249, 195]],
        ['#fde047', [253, 224, 71]],
        ['#ffe047', [255, 224, 71]],
        ['#ffff47', [255, 255, 71]],
        ['#000f47', [0, 15, 71]]
      ]

      pairs.each do |pair|
        expect(helper.hex_to_rgb(pair[0])).to eq(pair[1])
      end
    end
  end

  describe '#rgb_to_hex' do
    it 'converts RGB to a hex color' do
      pairs = [
        ['#fefce8', [254, 252, 232]],
        ['#fef9c3', [254, 249, 195]],
        ['#fde047', [253, 224, 71]],
        ['#ffe047', [255, 224, 71]],
        ['#ffff47', [255, 255, 71]],
        ['#000f47', [0, 15, 71]]
      ]

      pairs.each do |pair|
        expect(helper.rgb_to_hex(*pair[1])).to eq(pair[0])
      end
    end
  end

  describe '#get_luminance' do
    it 'gets luminance' do
      pairs = [
        ['#fefce8', 0.9651783305430648],
        ['#fef9c3', 0.9276232470289122],
        ['#fde047', 0.7464888809386645],
        ['#ffe047', 0.7502624139378438],
        ['#ffff47', 0.9323493232745587],
        ['#000f47', 0.007965800403950861]
      ]

      pairs.each do |pair|
        expect(helper.get_luminance(pair[0])).to be_within(0.0001).of(pair[1])
      end
    end
  end

  describe '#get_contrast' do
    it 'gets contrast' do
      pairs = [
        ['#fff7ed', '#082f49', 13.071630965576853],
        ['#ffedd5', '#0c4a6e', 8.25405437296673],
        ['#fed7aa', '#075985', 5.587542088216559],
        ['#fdba74', '#0369a1', 3.518444977234888],
        ['#fb923c', '#0284c7', 1.8094825558825534],
        ['#f97316', '#0ea5e9', 1.01141749353127],
        ['#ea580c', '#38bdf8', 1.66155548862194],
        ['#c2410c', '#7dd3fc', 3.1059042598363495],
        ['#9a3412', '#bae6fd', 5.506356434201567],
        ['#7c2d12', '#e0f2fe', 8.166263099299048],
        ['#431407', '#f0f9ff', 14.681391442562134]
      ]

      pairs.each do |pair|
        expect(helper.get_contrast(pair[0], pair[1])).to be_within(0.0001).of(pair[2])
      end
    end
  end

  describe '#mix' do
    it 'mixes at 0.5' do
      pairs = [
        ['#fff7ed', '#082f49', '#84939b'],
        ['#ffedd5', '#0c4a6e', '#869ca2'],
        ['#fed7aa', '#075985', '#839898'],
        ['#fdba74', '#0369a1', '#80928b'],
        ['#fb923c', '#0284c7', '#7e8b82'],
        ['#f97316', '#0ea5e9', '#848c80'],
        ['#ea580c', '#38bdf8', '#918b82'],
        ['#c2410c', '#7dd3fc', '#a08a84'],
        ['#9a3412', '#bae6fd', '#aa8d88'],
        ['#7c2d12', '#e0f2fe', '#ae9088'],
        ['#431407', '#f0f9ff', '#9a8783']
      ]

      pairs.each do |pair|
        expect(helper.mix(pair[0], pair[1], 0.5)).to eq(pair[2])
      end
    end

    it 'mixes at 0.2' do
      pairs = [
        ['#fff7ed', '#082f49', '#cecfcc'],
        ['#ffedd5', '#0c4a6e', '#ceccc0'],
        ['#fed7aa', '#075985', '#cdbea3'],
        ['#fdba74', '#0369a1', '#cbaa7d'],
        ['#fb923c', '#0284c7', '#c98f58'],
        ['#f97316', '#0ea5e9', '#ca7d40'],
        ['#ea580c', '#38bdf8', '#c66c3b'],
        ['#c2410c', '#7dd3fc', '#b45e3c'],
        ['#9a3412', '#bae6fd', '#a05841'],
        ['#7c2d12', '#e0f2fe', '#905441'],
        ['#431407', '#f0f9ff', '#664239']
      ]

      pairs.each do |pair|
        expect(helper.mix(pair[0], pair[1], 0.2)).to eq(pair[2])
      end
    end
  end

  describe '#adjust_color_for_contrast' do
    target_ratio = 3.1

    it 'adjusts a color to meet the contrast ratio against a light background' do
      color = '#ff0000'
      background_color = '#ffffff'
      adjusted_color = helper.adjust_color_for_contrast(color, background_color, target_ratio)
      ratio = helper.get_contrast(adjusted_color, background_color)

      expect(ratio).to be >= target_ratio
    end

    it 'adjusts a color to meet the contrast ratio against a dark background' do
      color = '#00ff00'
      background_color = '#000000'
      adjusted_color = helper.adjust_color_for_contrast(color, background_color, target_ratio)
      ratio = helper.get_contrast(adjusted_color, background_color)

      expect(ratio).to be >= target_ratio
    end

    it 'returns a string representation of the color' do
      color = '#00ff00'
      background_color = '#000000'
      adjusted_color = helper.adjust_color_for_contrast(color, background_color, target_ratio)

      expect(adjusted_color).to be_a(String)
    end

    it 'handles cases where the color already meets the contrast ratio' do
      color = '#000000'
      background_color = '#ffffff'
      adjusted_color = helper.adjust_color_for_contrast(color, background_color, target_ratio)
      ratio = helper.get_contrast(adjusted_color, background_color)

      expect(ratio).to be >= target_ratio
      expect(adjusted_color).to eq(color)
    end

    it 'does not modify a color that already exceeds the contrast ratio' do
      color = '#000000'
      background_color = '#ffffff'
      adjusted_color = helper.adjust_color_for_contrast(color, background_color, target_ratio)

      expect(adjusted_color).to eq(color)
    end
  end
end
