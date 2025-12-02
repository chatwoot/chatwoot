# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise::CsatSurveyResponsePolicy', type: :policy do
  subject(:csat_policy) { CsatSurveyResponsePolicy }

  let(:account) { create(:account) }
  let(:csat_survey_response) { create(:csat_survey_response, account: account) }

  # Create a custom role with report_manage permission
  let(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }
  let(:agent_with_role) { create(:user) } # Create without account
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end
  let(:agent_with_role_context) do
    { user: agent_with_role, account: account, account_user: agent_with_role_account_user }
  end

  permissions :index?, :metrics?, :download? do
    context 'when agent with report_manage permission' do
      it { expect(csat_policy).to permit(agent_with_role_context, csat_survey_response) }
    end
  end
end
