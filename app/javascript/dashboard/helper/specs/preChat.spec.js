import {
  getPreChatFields,
  getStandardFields,
  getCustomFields,
  getFormattedPreChatFields,
  getNonDeletedPreChatFields
} from '../preChat';
import inboxFixture from './inboxFixture';

const { customFields, customAttributes } = inboxFixture;
describe('#Pre chat Helpers', () => {
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
      ).toEqual('Share your queries or comments here.');
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
          label: 'Order Id',
          placeholder: 'Order Id',
          name: 'order_id',
          required: false,
          field_type: 'conversation_attribute',
          type: 'number',
          values: [],
        },
      ]);
    });
  });
  describe('getFormattedPreChatFields', () => {
    it('should return correct custom fields', () => {
      expect(
        getFormattedPreChatFields({
          preChatFields: customFields.pre_chat_fields,
        })
      ).toEqual([
        {
          label: 'Email Address',
          name: 'emailAddress',
          placeholder: 'Please enter your email address',
          type: 'email',
          field_type: 'standard',

          required: false,
          enabled: false,
        },
        {
          label: 'Full Name',
          name: 'fullName',
          placeholder: 'Please enter your full name',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
        {
          label: 'Phone Number',
          name: 'phoneNumber',
          placeholder: 'Please enter your phone number',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
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
          label: 'Email Address',
          name: 'emailAddress',
          placeholder: 'Please enter your email address',
          type: 'email',
          field_type: 'standard',

          required: false,
          enabled: false,
        },
        {
          label: 'Full name',
          name: 'fullName',
          placeholder: 'Please enter your full name',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
        {
          label: 'Phone number',
          name: 'phoneNumber',
          placeholder: 'Please enter your phone number',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
        {
          label: 'Order Id',
          name: 'order_id',
          placeholder: 'Order Id',
          type: 'number',
          values: [],
          field_type: 'conversation_attribute',
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
        getPreChatFields({ preChatFormOptions }).pre_chat_fields[0].required
      ).toEqual(true);
      expect(
        getPreChatFields({ preChatFormOptions }).pre_chat_fields[0].enabled
      ).toEqual(true);
      expect(getPreChatFields({ preChatFormOptions }).pre_chat_message).toEqual(
        'Share your queries here.'
      );
    });
  });
  describe('getNonDeletedPreChatFields', () => {
    it('should return non-deleted pre-chat fields', () => {
      expect(
        getNonDeletedPreChatFields({
          preChatFields: customFields.pre_chat_fields,
        })
      ).toEqual([
        {
          label: 'Email Address',
          name: 'emailAddress',
          placeholder: 'Please enter your email address',
          type: 'email',
          field_type: 'standard',

          required: false,
          enabled: false,
        },
        {
          label: 'Full Name',
          name: 'fullName',
          placeholder: 'Please enter your full name',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
        {
          label: 'Phone Number',
          name: 'phoneNumber',
          placeholder: 'Please enter your phone number',
          type: 'text',
          field_type: 'standard',
          required: false,
          enabled: false,
        },
      ]);
    });
  });
});
