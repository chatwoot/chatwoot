# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:administrator) { create(:user, :administrator) }
  let(:agent) { create(:user) }

  let(:user) { create(:user) }

  subject { described_class }

  permissions :create?, :update?, :destroy? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, user) }
    end

    context '#agent' do
      it { expect(subject).to_not permit(agent, user) }
    end
  end

  permissions :index? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, user) }
    end

    context '#agent' do
      it { expect(subject).to permit(agent, user) }
    end
  end
end
