require 'rails_helper'

RSpec.describe ConversationStatus, type: :model do
  it { is_expected.to belong_to(:account) }
end
