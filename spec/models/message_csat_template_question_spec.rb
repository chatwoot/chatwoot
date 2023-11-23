require 'rails_helper'

RSpec.describe MessageCsatTemplateQuestion do
  describe 'associations' do
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:csat_template_question) }
  end
end
