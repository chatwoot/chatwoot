require 'rails_helper'
require Rails.root.join('scripts/security/bundler_audit')

# The repo's own .bundler-audit.yml against Gemfile.lock and a current advisory database, cloned or
# pulled here as `bundle-audit update` does: an ignored id that matches no locked gem anymore means
# its fix landed (or the gem left), so the entry has to go.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'Ignores in .bundler-audit.yml' do
  # rubocop:enable RSpec/DescribeClass
  it 'only ignores advisories that still match a gem in Gemfile.lock' do
    database = if Bundler::Audit::Database.exists?
                 Bundler::Audit::Database.new.tap { |db| db.update!(quiet: true) }
               else
                 Bundler::Audit::Database.download(quiet: true)
               end

    expect(BundlerAuditExceptions.new(root: Rails.root.to_s, database: database).stale_ignores).to be_empty
  end
end
