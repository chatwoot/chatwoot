# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_numericality_of(:auto_resolve_duration).is_greater_than_or_equal_to(1) }

  it { is_expected.to have_many(:users).through(:account_users) }
  it { is_expected.to have_many(:account_users) }
  it { is_expected.to have_many(:inboxes).dependent(:destroy_async) }
  it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  it { is_expected.to have_many(:contacts).dependent(:destroy_async) }
  it { is_expected.to have_many(:telegram_bots).dependent(:destroy_async) }
  it { is_expected.to have_many(:canned_responses).dependent(:destroy_async) }
  it { is_expected.to have_many(:facebook_pages).class_name('::Channel::FacebookPage').dependent(:destroy_async) }
  it { is_expected.to have_many(:web_widgets).class_name('::Channel::WebWidget').dependent(:destroy_async) }
  it { is_expected.to have_many(:webhooks).dependent(:destroy_async) }
  it { is_expected.to have_many(:notification_settings).dependent(:destroy_async) }
  it { is_expected.to have_many(:events) }
  it { is_expected.to have_many(:kbase_portals).dependent(:destroy_async) }
  it { is_expected.to have_many(:kbase_categories).dependent(:destroy_async) }
  it { is_expected.to have_many(:teams).dependent(:destroy_async) }
end
