# frozen_string_literal: true

RSpec.shared_context 'with smtp config' do
  around do |example|
    # Set SMTP_ADDRESS so mailers build a Mail::Message in test without touching real SMTP.
    # Scoped to this shared context to avoid affecting other specs.
    with_modified_env('SMTP_ADDRESS' => 'smtp.example.com') { example.run }
  end
end
