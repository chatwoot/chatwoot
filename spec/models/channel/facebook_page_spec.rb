# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::FacebookPage do
  before { create(:channel_facebook_page) }

  it { is_expected.to validate_presence_of(:account_id) }
  it { is_expected.to validate_uniqueness_of(:page_id).scoped_to(:account_id) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_one(:inbox).dependent(:destroy) }
end
