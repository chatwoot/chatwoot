require 'rails_helper'

# Calendar is now a first-class capability of every Microsoft/Google mailbox connection:
# the OAuth scope must always request calendar access, gated only by the dedicated
# EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED kill-switch (default on), NOT by the CRM meetings flag.
RSpec.describe 'Email OAuth calendar scope' do # rubocop:disable RSpec/DescribeClass
  let(:microsoft) { Class.new { include MicrosoftConcern }.new }
  let(:google) { Class.new { include GoogleConcern }.new }

  describe 'Microsoft' do
    it 'always requests Calendars.ReadWrite by default' do
      expect(microsoft.send(:scope)).to include('https://graph.microsoft.com/Calendars.ReadWrite')
    end

    it 'keeps the full mail scope alongside calendar' do
      scope = microsoft.send(:scope)
      expect(scope).to include('https://outlook.office.com/IMAP.AccessAsUser.All')
      expect(scope).to include('https://graph.microsoft.com/Mail.Send')
      expect(scope).to include('https://graph.microsoft.com/Mail.ReadWrite')
    end

    it 'omits calendar only when explicitly disabled for the install' do
      with_modified_env EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED: 'false' do
        expect(microsoft.send(:scope)).not_to include('Calendars.ReadWrite')
      end
    end

    it 'is not coupled to the CRM meetings product flag' do
      with_modified_env CRM_CALENDAR_MEETINGS_ENABLED: 'false' do
        expect(microsoft.send(:scope)).to include('Calendars.ReadWrite')
      end
    end
  end

  describe 'Google' do
    it 'always requests the calendar scope by default' do
      expect(google.send(:scope)).to include('https://www.googleapis.com/auth/calendar')
    end

    it 'keeps the full mail scope alongside calendar' do
      expect(google.send(:scope)).to include('email profile https://mail.google.com/')
    end

    it 'omits calendar only when explicitly disabled for the install' do
      with_modified_env EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED: 'false' do
        expect(google.send(:scope)).not_to include('googleapis.com/auth/calendar')
      end
    end

    it 'is not coupled to the CRM meetings product flag' do
      with_modified_env CRM_CALENDAR_MEETINGS_ENABLED: 'false' do
        expect(google.send(:scope)).to include('googleapis.com/auth/calendar')
      end
    end
  end
end
