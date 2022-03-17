import {
  getInboxClassByType,
  getPreChatFields,
  getStandardFields,
  getCustomFields,
} from '../inbox';
import inboxFixture from './inboxFixture';
const { customFields, customAttributes } = inboxFixture;
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

  describe('getStandardFields', () => {
    it('should return correct standard fields if default form options passed', () => {
      const requireEmail = false;
      const emailEnabled = true;
      const preChatMessage = 'Share your queries or comments here.';
      expect(
        getStandardFields({ requireEmail, emailEnabled, preChatMessage })
          .pre_chat_fields[0].required
      ).toEqual(false);
      expect(
        getStandardFields({ requireEmail, emailEnabled, preChatMessage })
          .pre_chat_fields[0].enabled
      ).toEqual(true);
      expect(
        getStandardFields({ requireEmail, emailEnabled, preChatMessage })
          .pre_chat_message
      ).toEqual('Share your queries here.');
    });
  });
  describe('getCustomFields', () => {
    it('should return correct custom fields', () => {
      const requireEmail = false;
      const emailEnabled = true;
      const preChatMessage = 'Share your queries or comments here.';
      const standardFields = getStandardFields({
        requireEmail,
        emailEnabled,
        preChatMessage,
      });
      expect(getCustomFields({ standardFields, customAttributes })).toEqual([
        {
          enabled: false,
          field_type: 'custom',
          label: 'Order Id',
          name: 'order_id',
          required: false,
          type: 'number',
          values: [],
        },
      ]);
    });
  });
  describe('getPreChatFields', () => {
    it('should return correct pre-chat fields form options passed', () => {
      expect(getPreChatFields({ preChatFormOptions: customFields })).toEqual(
        customFields
      );
    });
    it('should return correct pre-chat fields if empty form options passed', () => {
      const preChatFormOptions = {};
      expect(
        getPreChatFields({ preChatFormOptions, customAttributes })
          .pre_chat_fields
      ).toEqual([
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
        {
          label: 'Order Id',
          name: 'order_id',
          type: 'number',
          values: [],
          field_type: 'custom',
          required: false,
          enabled: false,
        },
      ]);
    });
    it('should return correct pre-chat fields if default form options passed', () => {
      const preChatFormOptions = {
        pre_chat_message: 'Share your queries here.',
        require_email: true,
      };
      expect(
        getPreChatFields(preChatFormOptions).pre_chat_fields[0].required
      ).toEqual(true);
      expect(
        getPreChatFields(preChatFormOptions).pre_chat_fields[0].enabled
      ).toEqual(true);
      expect(getPreChatFields(preChatFormOptions).pre_chat_message).toEqual(
        'Share your queries here.'
      );
    });
  });
});
