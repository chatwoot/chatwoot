# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxPolicy, type: :policy do
  subject(:inbox_policy) { described_class }

  let(:administrator) { create(:user, :administrator) }
  let(:agent) { create(:user) }
  let(:inbox) { create(:inbox) }

  permissions :create?, :destroy? do
    context 'when administrator' do
      it { expect(inbox_policy).to permit(administrator, inbox) }
    end

    context 'when agent' do
      it { expect(inbox_policy).not_to permit(agent, inbox) }
    end
  end

  permissions :index? do
    context 'when administrator' do
      it { expect(inbox_policy).to permit(administrator, inbox) }
    end

    context 'when agent' do
      it { expect(inbox_policy).to permit(agent, inbox) }
    end
  end
end
