# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxPolicy, type: :policy do
  let(:administrator) { create(:user, :administrator) }
  let(:agent) { create(:user) }

  let(:inbox) { create(:inbox) }

  subject { described_class }

  permissions :create?, :destroy? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, inbox) }
    end

    context '#agent' do
      it { expect(subject).to_not permit(agent, inbox) }
    end
  end

  permissions :index? do
    context '#administrator' do
      it { expect(subject).to permit(administrator, inbox) }
    end

    context '#agent' do
      it { expect(subject).to permit(agent, inbox) }
    end
  end
end
