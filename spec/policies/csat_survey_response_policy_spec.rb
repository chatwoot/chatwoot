# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsatSurveyResponsePolicy, type: :policy do
  subject(:csat_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:csat_survey_response) { create(:csat_survey_response, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.last } }

  permissions :index?, :metrics?, :download? do
    context 'when administrator' do
      it { expect(csat_policy).to permit(administrator_context, csat_survey_response) }
    end

    context 'when agent' do
      it { expect(csat_policy).not_to permit(agent_context, csat_survey_response) }
    end
  end
end
