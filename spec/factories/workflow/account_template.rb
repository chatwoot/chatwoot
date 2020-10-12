FactoryBot.define do
  factory :workflow_account_template, class: 'Workflow::AccountTemplate' do
    account
    template_id { Workflow::Template.all.first.id }
  end
end
