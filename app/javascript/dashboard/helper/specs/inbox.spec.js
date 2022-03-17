import { getInboxClassByType, getCustomFields } from '../inbox';
const customFields = {
  pre_chat_message: 'Share your queries or comments here.',
  pre_chat_fields: [
    {
      label: 'Email Id',
      name: 'emailAddress',
      type: 'email',
      field_type: 'standard',
      required: false,
      enabled: false,
    },
    {
      label: 'Full name',
      name: 'fullName',
      type: 'text',
      field_type: 'standard',
      required: false,
      enabled: false,
    },
    {
      label: 'Phone number',
      name: 'phoneNumber',
      type: 'text',
      field_type: 'standard',
      required: false,
      enabled: false,
    },
  ],
};
describe('#Inbox Helpers', () => {
  describe('getInboxClassByType', () => {
    it('should return correct class for web widget', () => {
      expect(getInboxClassByType('Channel::WebWidget')).toEqual(
        'globe-desktop'
      );
    });
    it('should return correct class for fb page', () => {
      expect(getInboxClassByType('Channel::FacebookPage')).toEqual(
        'brand-facebook'
      );
    });
    it('should return correct class for  twitter profile', () => {
      expect(getInboxClassByType('Channel::TwitterProfile')).toEqual(
        'brand-twitter'
      );
    });
    it('should return correct class for twilio sms', () => {
      expect(getInboxClassByType('Channel::TwilioSms', '')).toEqual(
        'brand-sms'
      );
    });
    it('should return correct class for whatsapp', () => {
      expect(getInboxClassByType('Channel::TwilioSms', 'whatsapp')).toEqual(
        'brand-whatsapp'
      );
    });
    it('should return correct class for Api', () => {
      expect(getInboxClassByType('Channel::Api')).toEqual('cloud');
    });
    it('should return correct class for Email', () => {
      expect(getInboxClassByType('Channel::Email')).toEqual('mail');
    });
  });
  describe('getCustomFields', () => {
    it('should return correct custom fields form options passed', () => {
      expect(getCustomFields(customFields)).toEqual(customFields);
    });
    it('should return correct custom fields if empty form options passed', () => {
      const preChatFormOptions = {};
      expect(getCustomFields(preChatFormOptions)).toEqual(customFields);
    });
    it('should return correct custom fields if default form options passed', () => {
      const preChatFormOptions = {
        pre_chat_message: 'Share your queries here.',
        require_email: true,
      };
      expect(
        getCustomFields(preChatFormOptions).pre_chat_fields[0].required
      ).toEqual(true);
      expect(
        getCustomFields(preChatFormOptions).pre_chat_fields[0].enabled
      ).toEqual(true);
      expect(getCustomFields(preChatFormOptions).pre_chat_message).toEqual(
        'Share your queries here.'
      );
    });
  });
});
