# frozen_string_literal: true

RSpec.shared_context 'with smtp config' do
  before do
    # We need to use allow_any_instance_of here because smtp_config_set_or_development?
    # is defined in ApplicationMailer and needs to be stubbed for all mailer instances
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationMailer).to receive(:smtp_config_set_or_development?).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end
end
