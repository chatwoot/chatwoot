require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Content Security Policy Configuration' do
  # rubocop:enable RSpec/DescribeClass

  # The CSP initializer reads ENABLE_CSP_REPORT_ONLY at boot time, so the
  # current process can only assert the boot-time outcome. We test what the
  # initializer produces by re-loading it with a stubbed ENV.
  let(:initializer_path) { Rails.root.join('config/initializers/content_security_policy.rb') }

  def reload_initializer
    # Reset so a previous run does not leak into this one.
    Rails.application.config.content_security_policy = nil
    Rails.application.config.content_security_policy_report_only = false
    load initializer_path
  end

  context 'when ENABLE_CSP_REPORT_ONLY is unset (default)' do
    around do |example|
      ClimateControl.modify(ENABLE_CSP_REPORT_ONLY: nil) { example.run }
    end

    it 'does not configure a content security policy' do
      reload_initializer
      expect(Rails.application.config.content_security_policy).to be_nil
    end
  end

  context 'when ENABLE_CSP_REPORT_ONLY is true' do
    around do |example|
      ClimateControl.modify(ENABLE_CSP_REPORT_ONLY: 'true') { example.run }
    end

    it 'configures a content security policy in report-only mode' do
      reload_initializer
      expect(Rails.application.config.content_security_policy).to be_a(ActionDispatch::ContentSecurityPolicy)
      expect(Rails.application.config.content_security_policy_report_only).to be(true)
    end

    it 'sets restrictive defaults that still allow https assets' do
      reload_initializer
      policy = Rails.application.config.content_security_policy

      expect(policy.default_src).to include("'self'", 'https:')
      expect(policy.object_src).to eq(["'none'"])
      expect(policy.frame_ancestors).to eq(["'self'"])
      expect(policy.base_uri).to eq(["'self'"])
    end

    it 'does not set a report_uri when CSP_REPORT_URI is unset' do
      ClimateControl.modify(CSP_REPORT_URI: nil) do
        reload_initializer
        # ContentSecurityPolicy stores @report_uri internally; a nil value means
        # the report-uri directive is omitted from the rendered header.
        expect(Rails.application.config.content_security_policy.instance_variable_get(:@report_uri)).to be_nil
      end
    end

    it 'sets report_uri when CSP_REPORT_URI is provided' do
      ClimateControl.modify(CSP_REPORT_URI: 'https://example.com/csp-report') do
        reload_initializer
        expect(Rails.application.config.content_security_policy.instance_variable_get(:@report_uri)).to eq('https://example.com/csp-report')
      end
    end
  end

  context 'when ENABLE_CSP_REPORT_ONLY is set to a falsy string' do
    around do |example|
      ClimateControl.modify(ENABLE_CSP_REPORT_ONLY: 'false') { example.run }
    end

    it 'does not configure a content security policy' do
      reload_initializer
      expect(Rails.application.config.content_security_policy).to be_nil
    end
  end
end
