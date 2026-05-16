require 'rails_helper'

# The accounts.feature_flags column is a signed bigint, which gives 63 usable
# bit slots (bit 63 is the sign bit). Each entry in config/features.yml is
# bound to the bit position implied by its index in the file, so inserting,
# removing, or reordering entries silently reinterprets stored feature_flags
# values for every existing account.
#
# These specs are deliberately minimal regressions:
#   * Cap the count so a 64th feature can't ship without triaging the column
#     overflow first (an issue and a discussion thread should accompany any
#     bump above 63 — likely a reclaim of a deprecated slot).
#   * Detect duplicate names so a typo or merge conflict cannot quietly map
#     two features to the same bit.
# rubocop:disable RSpec/DescribeClass
describe 'config/features.yml' do
  # rubocop:enable RSpec/DescribeClass
  let(:features) { YAML.safe_load(Rails.root.join('config/features.yml').read) }

  it 'stays within the 63-bit ceiling of the signed bigint feature_flags column' do
    expect(features.size).to be <= 63,
                              "config/features.yml has #{features.size} entries, but the signed bigint " \
                              'accounts.feature_flags column only supports 63 bit slots (bit 63 is the sign bit). ' \
                              'Reclaim a `deprecated: true` entry by renaming it in place instead of appending. ' \
                              'See the protocol notes at the top of config/features.yml.'
  end

  it 'has no duplicate feature names' do
    names = features.pluck('name')
    duplicates = names.tally.select { |_, n| n > 1 }.keys
    expect(duplicates).to be_empty, "Duplicate feature names in config/features.yml: #{duplicates}"
  end
end
