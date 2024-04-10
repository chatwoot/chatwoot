import {
  getPreChatFields,
  getFormattedPreChatFields,
  getCustomFields,
} from '../preChat';
import inboxFixture from './inboxFixture';

const { customFields, customAttributes } = inboxFixture;
describe('#Pre chat Helpers', () => {
  describe('getPreChatFields', () => {
    it('should return correct pre-chat fields form options passed', () => {
      expect(getPreChatFields({ preChatFormOptions: customFields })).toEqual(
        customFields
      );
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
  describe('getCustomFields', () => {
    it('should return correct custom fields', () => {
      expect(
        getCustomFields({
          standardFields: { pre_chat_fields: customFields.pre_chat_fields },
          customAttributes,
        })
      ).toEqual([
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
});
