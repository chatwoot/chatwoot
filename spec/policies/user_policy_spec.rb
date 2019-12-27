# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:user_policy) { described_class }

  let(:administrator) { create(:user, :administrator) }
  let(:agent) { create(:user) }
  let(:user) { create(:user) }

  permissions :create?, :update?, :destroy? do
    context 'when administrator' do
      it { expect(user_policy).to permit(administrator, user) }
    end

    context 'when agent' do
      it { expect(user_policy).not_to permit(agent, user) }
    end
  end

  permissions :index? do
    context 'when administrator' do
      it { expect(user_policy).to permit(administrator, user) }
    end

    context 'when agent' do
      it { expect(user_policy).to permit(agent, user) }
    end
  end
end
