# frozen_string_literal: true

require 'rails_helper' 

RSpec.describe 'Confirmation Instructions', type: :mailer do
  describe :notify do
    let(:admin_user) { FactoryBot.create(:user, role: :administrator) }
    let(:confirmable_user) { FactoryBot.build(:user, inviter: admin_user) }

    let(:mail) { confirmable_user.confirm! }

    it do
      binding.pry
    end
  end
end
