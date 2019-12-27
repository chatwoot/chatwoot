# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactPolicy, type: :policy do
  let(:administrator) { create(:user, :administrator) }
  let(:agent) { create(:user) }

  let(:contact) { create(:contact) }

  subject { described_class }

  permissions :index?, :show?, :update? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, contact) }
    end

    context '#agent' do
      it { expect(subject).to_not permit(agent, contact) }
    end
  end

  permissions :create? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, contact) }
    end

    context '#agent' do
      it { expect(subject).to permit(agent, contact) }
    end
  end
end
