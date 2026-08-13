require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  include ActiveJob::TestHelper

  describe 'audit_log:backfill_ip_location' do
    subject(:task) { described_class['audit_log:backfill_ip_location'] }

    before { task.reenable }

    it 'kicks off the throttled backfill job' do
      clear_enqueued_jobs
      task.invoke
      expect(Enterprise::AuditLogIpLocationBackfillJob).to have_been_enqueued
    end
  end
end
