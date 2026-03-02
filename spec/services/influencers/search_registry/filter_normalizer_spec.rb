require 'rails_helper'

RSpec.describe Influencers::SearchRegistry::FilterNormalizer do
  describe '#perform' do
    it 'normalizes blank values, numeric strings, and array ordering deterministically' do
      filters = {
        ai_search: ' home decor ',
        followers: { max: '30000', min: '5000' },
        hashtags: ['interior', ' ', 'decor'],
        location: %w[Poland Germany],
        profile_language: %w[pl de],
        keywords_in_bio: [' design', 'home '],
        engagement_percent_min: '1.5',
        gender: 'female',
        avg_reels_min: '',
        reels_percent_min: nil
      }

      normalized = described_class.new(filters).perform

      expect(normalized).to eq(
        {
          'ai_search' => 'home decor',
          'engagement_percent_min' => 1.5,
          'followers' => { 'max' => 30_000, 'min' => 5000 },
          'gender' => 'female',
          'hashtags' => %w[decor interior],
          'keywords_in_bio' => %w[design home],
          'location' => %w[Germany Poland],
          'profile_language' => %w[de pl]
        }
      )
    end
  end

  describe '#signature' do
    it 'returns the same signature for semantically identical filters' do
      filters_a = {
        hashtags: %w[decor interior],
        location: %w[Poland Germany],
        followers: { min: '5000', max: '30000' }
      }
      filters_b = {
        followers: { max: 30_000, min: 5000 },
        location: %w[Germany Poland],
        hashtags: %w[interior decor]
      }

      signature_a = described_class.new(filters_a).signature
      signature_b = described_class.new(filters_b).signature

      expect(signature_a).to eq(signature_b)
    end
  end
end
