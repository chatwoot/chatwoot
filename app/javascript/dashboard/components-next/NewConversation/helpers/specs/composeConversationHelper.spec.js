import { describe, it, expect } from 'vitest';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import * as helpers from '../composeConversationHelper';

describe('composeConversationHelper', () => {
  describe('convertChannelTypeToLabel', () => {
    it('converts channel type with namespace to capitalized label', () => {
      expect(helpers.convertChannelTypeToLabel('Channel::Email')).toBe('Email');
      expect(helpers.convertChannelTypeToLabel('Channel::Whatsapp')).toBe(
        'Whatsapp'
      );
    });

    it('returns original value if no namespace found', () => {
      expect(helpers.convertChannelTypeToLabel('email')).toBe('email');
    });
  });

  describe('generateLabelForContactableInboxesList', () => {
    const contact = {
      name: 'John Doe',
      email: 'john@example.com',
      phoneNumber: '+1234567890',
    };

    it('generates label for email inbox', () => {
      expect(
        helpers.generateLabelForContactableInboxesList({
          ...contact,
          channelType: INBOX_TYPES.EMAIL,
        })
      ).toBe('John Doe (john@example.com)');
    });

    it('generates label for twilio inbox', () => {
      expect(
        helpers.generateLabelForContactableInboxesList({
          ...contact,
          channelType: INBOX_TYPES.TWILIO,
        })
      ).toBe('John Doe (+1234567890)');
    });

    it('generates label for whatsapp inbox', () => {
      expect(
        helpers.generateLabelForContactableInboxesList({
          ...contact,
          channelType: INBOX_TYPES.WHATSAPP,
        })
      ).toBe('John Doe (+1234567890)');
    });

    it('generates label for other inbox types', () => {
      expect(
        helpers.generateLabelForContactableInboxesList({
          ...contact,
          channelType: 'Channel::Api',
        })
      ).toBe('John Doe (Api)');
    });
  });

  describe('buildContactableInboxesList', () => {
    it('returns empty array if no contact inboxes', () => {
      expect(helpers.buildContactableInboxesList(null)).toEqual([]);
      expect(helpers.buildContactableInboxesList(undefined)).toEqual([]);
    });

    it('builds list of contactable inboxes with correct format', () => {
      const inboxes = [
        {
          id: 1,
          name: 'Email Inbox',
          email: 'support@example.com',
          channelType: INBOX_TYPES.EMAIL,
          phoneNumber: null,
        },
      ];

      const result = helpers.buildContactableInboxesList(inboxes);
      expect(result[0]).toMatchObject({
        id: 1,
        label: 'Email Inbox (support@example.com)',
        action: 'inbox',
        value: 1,
        name: 'Email Inbox',
        email: 'support@example.com',
        channelType: INBOX_TYPES.EMAIL,
      });
    });
  });

  describe('prepareAttachmentPayload', () => {
    it('prepares direct upload files', () => {
      const files = [{ blobSignedId: 'signed1' }];
      expect(helpers.prepareAttachmentPayload(files, true)).toEqual([
        'signed1',
      ]);
    });

    it('prepares regular files', () => {
      const files = [{ resource: { file: 'file1' } }];
      expect(helpers.prepareAttachmentPayload(files, false)).toEqual(['file1']);
    });
  });

  describe('prepareNewMessagePayload', () => {
    const baseParams = {
      targetInbox: { id: 1, sourceId: 'source1' },
      selectedContact: { id: '2' },
      message: 'Hello',
      currentUser: { id: 3 },
    };

    it('prepares basic message payload', () => {
      const result = helpers.prepareNewMessagePayload(baseParams);
      expect(result).toEqual({
        inboxId: 1,
        sourceId: 'source1',
        contactId: 2,
        message: { content: 'Hello' },
        assigneeId: 3,
      });
    });

    it('includes optional fields when provided', () => {
      const result = helpers.prepareNewMessagePayload({
        ...baseParams,
        subject: 'Test',
        ccEmails: 'cc@test.com',
        bccEmails: 'bcc@test.com',
        attachedFiles: [{ blobSignedId: 'file1' }],
        directUploadsEnabled: true,
      });

      expect(result).toMatchObject({
        mailSubject: 'Test',
        message: {
          content: 'Hello',
          cc_emails: 'cc@test.com',
          bcc_emails: 'bcc@test.com',
        },
        files: ['file1'],
      });
    });
  });

  describe('prepareWhatsAppMessagePayload', () => {
    it('prepares whatsapp message payload', () => {
      const params = {
        targetInbox: { id: 1, sourceId: 'source1' },
        selectedContact: { id: 2 },
        message: 'Hello',
        templateParams: { param1: 'value1' },
        currentUser: { id: 3 },
      };

      const result = helpers.prepareWhatsAppMessagePayload(params);
      expect(result).toEqual({
        inboxId: 1,
        sourceId: 'source1',
        contactId: 2,
        message: {
          content: 'Hello',
          template_params: { param1: 'value1' },
        },
        assigneeId: 3,
      });
    });
  });
});
