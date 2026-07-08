# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Featurable do
  describe '.feature_flag_mappings_for' do
    it 'maps features to the default feature_flags column when column is omitted' do
      mappings = described_class.feature_flag_mappings_for([
                                                             { 'name' => 'inbound_emails' },
                                                             { 'name' => 'ip_lookup' }
                                                           ])

      expect(mappings['feature_flags']).to eq(
        1 => :feature_inbound_emails,
        2 => :feature_ip_lookup
      )
      expect(mappings['feature_flags_ext_1']).to eq({})
    end

    it 'maps extension flags to feature_flags_ext_1 with independent bit positions' do
      mappings = described_class.feature_flag_mappings_for([
                                                             { 'name' => 'inbound_emails' },
                                                             { 'name' => 'ext_one', 'column' => 'feature_flags_ext_1' },
                                                             { 'name' => 'ext_two', 'column' => 'feature_flags_ext_1' }
                                                           ])

      expect(mappings['feature_flags']).to eq(1 => :feature_inbound_emails)
      expect(mappings['feature_flags_ext_1']).to eq(
        1 => :feature_ext_one,
        2 => :feature_ext_two
      )
    end

    it 'raises when a feature references an unknown flag column' do
      expect do
        described_class.feature_flag_mappings_for([
                                                    { 'name' => 'unknown_column_feature', 'column' => 'feature_flags_3' }
                                                  ])
      end.to raise_error(ArgumentError, /Unknown account feature flag column: feature_flags_3/)
    end

    it 'raises when a flag column has more than the supported number of features' do
      features = Array.new(64) { |index| { 'name' => "feature_#{index}" } }

      expect do
        described_class.feature_flag_mappings_for(features)
      end.to raise_error(ArgumentError, /feature_flags supports up to 63 features/)
    end
  end
end
