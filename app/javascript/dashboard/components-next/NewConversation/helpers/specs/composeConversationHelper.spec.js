import { describe, it, expect, vi } from 'vitest';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import ContactAPI from 'dashboard/api/contacts';
import * as helpers from '../composeConversationHelper';

vi.mock('dashboard/api/contacts');

describe('composeConversationHelper', () => {
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
      ).toBe('John Doe');
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
        icon: 'i-ri-mail-line',
        label: 'Email Inbox (support@example.com)',
        action: 'inbox',
        value: 1,
        name: 'Email Inbox',
        email: 'support@example.com',
        channelType: INBOX_TYPES.EMAIL,
      });
    });
  });

  describe('getCapitalizedNameFromEmail', () => {
    it('extracts and capitalizes name from email', () => {
      expect(helpers.getCapitalizedNameFromEmail('john.doe@example.com')).toBe(
        'John.doe'
      );
      expect(helpers.getCapitalizedNameFromEmail('jane@example.com')).toBe(
        'Jane'
      );
    });
  });

  describe('processContactableInboxes', () => {
    it('processes inboxes with correct structure', () => {
      const inboxes = [
        {
          inbox: { id: 1, name: 'Inbox 1' },
          sourceId: 'source1',
        },
      ];

      const result = helpers.processContactableInboxes(inboxes);
      expect(result[0]).toEqual({
        id: 1,
        name: 'Inbox 1',
        sourceId: 'source1',
      });
    });
  });

  describe('mergeInboxDetails', () => {
    it('returns empty array if inboxesData is empty or null', () => {
      expect(helpers.mergeInboxDetails(null)).toEqual([]);
      expect(helpers.mergeInboxDetails([])).toEqual([]);
      expect(helpers.mergeInboxDetails(undefined)).toEqual([]);
    });

    it('merges inbox data with matching inboxes from the list', () => {
      const inboxesData = [
        { id: 1, sourceId: 'source1' },
        { id: 2, sourceId: 'source2' },
      ];

      const inboxesList = [
        {
          id: 1,
          name: 'Inbox 1',
          channel_type: 'Channel::Email',
          channel_id: 10,
          phone_number: null,
        },
        {
          id: 2,
          name: 'Inbox 2',
          channel_type: 'Channel::Whatsapp',
          channel_id: 20,
          phone_number: '+1234567890',
        },
        {
          id: 3,
          name: 'Inbox 3',
          channel_type: 'Channel::Api',
          channel_id: 30,
          phone_number: null,
        },
      ];

      const result = helpers.mergeInboxDetails(inboxesData, inboxesList);

      expect(result.length).toBe(2);
      expect(result[0]).toMatchObject({
        id: 1,
        sourceId: 'source1',
        name: 'Inbox 1',
        channelType: 'Channel::Email',
        channelId: 10,
        phoneNumber: null,
      });

      expect(result[1]).toMatchObject({
        id: 2,
        sourceId: 'source2',
        name: 'Inbox 2',
        channelType: 'Channel::Whatsapp',
        channelId: 20,
        phoneNumber: '+1234567890',
      });
    });

    it('handles inboxes not found in the list', () => {
      const inboxesData = [
        { id: 1, sourceId: 'source1' },
        { id: 99, sourceId: 'source99' }, // This doesn't exist in inboxesList
      ];

      const inboxesList = [
        {
          id: 1,
          name: 'Inbox 1',
          channel_type: 'Channel::Email',
        },
      ];

      const result = helpers.mergeInboxDetails(inboxesData, inboxesList);

      expect(result.length).toBe(2);

      expect(result[0]).toMatchObject({
        id: 1,
        sourceId: 'source1',
        name: 'Inbox 1',
        channelType: 'Channel::Email',
      });

      expect(result[1]).toMatchObject({
        id: 99,
        sourceId: 'source99',
      });

      expect(result[1].name).toBeUndefined();
      expect(result[1].channelType).toBeUndefined();
    });

    it('camelcases properties from inboxesList', () => {
      const inboxesData = [{ id: 1, sourceId: 'source1' }];

      const inboxesList = [
        {
          id: 1,
          name: 'Inbox 1',
          channel_type: 'Channel::Email',
          avatar_url: 'https://example.com/avatar.png',
          working_hours: [
            {
              day_of_week: 1,
              closed_all_day: false,
            },
          ],
        },
      ];

      const result = helpers.mergeInboxDetails(inboxesData, inboxesList);

      expect(result[0]).toMatchObject({
        id: 1,
        sourceId: 'source1',
        name: 'Inbox 1',
        channelType: 'Channel::Email',
        avatarUrl: 'https://example.com/avatar.png',
      });

      expect(result[0].workingHours[0]).toMatchObject({
        dayOfWeek: 1,
        closedAllDay: false,
      });
    });

    it('preserves original properties when they conflict with inboxesList', () => {
      const inboxesData = [
        { id: 1, sourceId: 'source1', name: 'Original Name' },
      ];

      const inboxesList = [
        {
          id: 1,
          name: 'List Name',
          channel_type: 'Channel::Email',
        },
      ];

      const result = helpers.mergeInboxDetails(inboxesData, inboxesList);

      expect(result[0].name).toBe('Original Name');
      expect(result[0].channelType).toBe('Channel::Email');
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

  describe('generateContactQuery', () => {
    it('generates correct query structure for contact search', () => {
      const query = 'test@example.com';
      const expected = {
        payload: [
          {
            attribute_key: 'email',
            filter_operator: 'contains',
            values: [query],
            attribute_model: 'standard',
          },
        ],
      };

      expect(helpers.generateContactQuery({ keys: ['email'], query })).toEqual(
        expected
      );
    });

    it('handles empty query', () => {
      const expected = {
        payload: [
          {
            attribute_key: 'email',
            filter_operator: 'contains',
            values: [''],
            attribute_model: 'standard',
          },
        ],
      };

      expect(
        helpers.generateContactQuery({ keys: ['email'], query: '' })
      ).toEqual(expected);
    });

    it('handles mutliple keys', () => {
      const expected = {
        payload: [
          {
            attribute_key: 'email',
            filter_operator: 'contains',
            values: ['john'],
            attribute_model: 'standard',
            query_operator: 'or',
          },
          {
            attribute_key: 'phone_number',
            filter_operator: 'contains',
            values: ['john'],
            attribute_model: 'standard',
          },
        ],
      };

      expect(
        helpers.generateContactQuery({
          keys: ['email', 'phone_number'],
          query: 'john',
        })
      ).toEqual(expected);
    });
  });

  describe('API calls', () => {
    describe('searchContacts', () => {
      it('searches contacts and returns camelCase results', async () => {
        const mockPayload = [
          {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            phone_number: '+1234567890',
            created_at: '2023-01-01',
          },
        ];

        ContactAPI.filter.mockResolvedValue({
          data: { payload: mockPayload },
        });

        const result = await helpers.searchContacts({
          keys: ['email'],
          query: 'john',
        });

        expect(result).toEqual([
          {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            phoneNumber: '+1234567890',
            createdAt: '2023-01-01',
          },
        ]);

        expect(ContactAPI.filter).toHaveBeenCalledWith(undefined, 'name', {
          payload: [
            {
              attribute_key: 'email',
              filter_operator: 'contains',
              values: ['john'],
              attribute_model: 'standard',
            },
          ],
        });
      });

      it('searches contacts and returns only contacts with email or phone number', async () => {
        const mockPayload = [
          {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            phone_number: '+1234567890',
            created_at: '2023-01-01',
          },
          {
            id: 2,
            name: 'Jane Doe',
            email: null,
            phone_number: null,
            created_at: '2023-01-01',
          },
          {
            id: 3,
            name: 'Bob Smith',
            email: 'bob@example.com',
            phone_number: null,
            created_at: '2023-01-01',
          },
        ];

        ContactAPI.filter.mockResolvedValue({
          data: { payload: mockPayload },
        });

        const result = await helpers.searchContacts({
          keys: ['email'],
          query: 'john',
        });

        // Should only return contacts with either email or phone number
        expect(result).toEqual([
          {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            phoneNumber: '+1234567890',
            createdAt: '2023-01-01',
          },
          {
            id: 3,
            name: 'Bob Smith',
            email: 'bob@example.com',
            phoneNumber: null,
            createdAt: '2023-01-01',
          },
        ]);

        expect(ContactAPI.filter).toHaveBeenCalledWith(undefined, 'name', {
          payload: [
            {
              attribute_key: 'email',
              filter_operator: 'contains',
              values: ['john'],
              attribute_model: 'standard',
            },
          ],
        });
      });

      it('handles empty search results', async () => {
        ContactAPI.filter.mockResolvedValue({
          data: { payload: [] },
        });

        const result = await helpers.searchContacts('nonexistent');
        expect(result).toEqual([]);
      });

      it('transforms nested objects to camelCase', async () => {
        const mockPayload = [
          {
            id: 1,
            name: 'John Doe',
            phone_number: '+1234567890',
            contact_inboxes: [
              {
                inbox_id: 1,
                source_id: 'source1',
                created_at: '2023-01-01',
              },
            ],
            custom_attributes: {
              custom_field_name: 'value',
            },
          },
        ];

        ContactAPI.filter.mockResolvedValue({
          data: { payload: mockPayload },
        });

        const result = await helpers.searchContacts('test');

        expect(result).toEqual([
          {
            id: 1,
            name: 'John Doe',
            phoneNumber: '+1234567890',
            contactInboxes: [
              {
                inboxId: 1,
                sourceId: 'source1',
                createdAt: '2023-01-01',
              },
            ],
            customAttributes: {
              customFieldName: 'value',
            },
          },
        ]);
      });
    });

    describe('createNewContact', () => {
      it('creates new contact with capitalized name', async () => {
        const mockContact = { id: 1, name: 'John', email: 'john@example.com' };
        ContactAPI.create.mockResolvedValue({
          data: { payload: { contact: mockContact } },
        });

        const result = await helpers.createNewContact('john@example.com');
        expect(result).toEqual(mockContact);
        expect(ContactAPI.create).toHaveBeenCalledWith({
          name: 'John',
          email: 'john@example.com',
        });
      });

      it('creates new contact with phone number', async () => {
        const mockContact = {
          id: 1,
          name: '919999999999',
          phone_number: '+919999999999',
        };
        ContactAPI.create.mockResolvedValue({
          data: { payload: { contact: mockContact } },
        });

        const result = await helpers.createNewContact('+919999999999');
        expect(result).toEqual({
          id: 1,
          name: '919999999999',
          phoneNumber: '+919999999999',
        });
        expect(ContactAPI.create).toHaveBeenCalledWith({
          name: '919999999999',
          phone_number: '+919999999999',
        });
      });
    });

    describe('fetchContactableInboxes', () => {
      it('fetches and processes contactable inboxes', async () => {
        const mockInboxes = [
          {
            inbox: { id: 1, name: 'Inbox 1' },
            sourceId: 'source1',
          },
        ];
        ContactAPI.getContactableInboxes.mockResolvedValue({
          data: { payload: mockInboxes },
        });

        const result = await helpers.fetchContactableInboxes(1);
        expect(result[0]).toEqual({
          id: 1,
          name: 'Inbox 1',
          sourceId: 'source1',
        });
        expect(ContactAPI.getContactableInboxes).toHaveBeenCalledWith(1);
      });

      it('returns empty array when no inboxes found', async () => {
        ContactAPI.getContactableInboxes.mockResolvedValue({
          data: { payload: [] },
        });

        const result = await helpers.fetchContactableInboxes(1);
        expect(result).toEqual([]);
      });
    });
  });
});

describe('compareInboxes', () => {
  it('should sort inboxes by channel priority', () => {
    const inboxes = [
      { channelType: 'Channel::Api', name: 'API Inbox' },
      { channelType: 'Channel::Email', name: 'Email Inbox' },
      { channelType: 'Channel::WebWidget', name: 'Widget' },
      { channelType: 'Channel::Whatsapp', name: 'WhatsApp' },
    ];

    const sorted = [...inboxes].sort(helpers.compareInboxes);

    expect(sorted[0].channelType).toBe('Channel::Email');
    expect(sorted[1].channelType).toBe('Channel::Whatsapp');
    expect(sorted[2].channelType).toBe('Channel::WebWidget');
    expect(sorted[3].channelType).toBe('Channel::Api');
  });

  it('should sort SMS channels correctly', () => {
    const inboxes = [
      { channelType: 'Channel::TwilioSms', name: 'Twilio' },
      { channelType: 'Channel::Sms', name: 'Regular SMS' },
    ];

    const sorted = [...inboxes].sort(helpers.compareInboxes);

    expect(sorted[0].channelType).toBe('Channel::Sms');
    expect(sorted[1].channelType).toBe('Channel::TwilioSms');
  });

  it('should sort by name when channel types are same', () => {
    const inboxes = [
      { channelType: 'Channel::Email', name: 'Support' },
      { channelType: 'Channel::Email', name: 'Marketing' },
      { channelType: 'Channel::Email', name: 'Billing' },
    ];

    const sorted = [...inboxes].sort(helpers.compareInboxes);

    expect(sorted.map(inbox => inbox.name)).toEqual([
      'Billing',
      'Marketing',
      'Support',
    ]);
  });

  it('should put channels without priority at the end', () => {
    const inboxes = [
      { channelType: 'Channel::Unknown', name: 'Unknown' },
      { channelType: 'Channel::Email', name: 'Email' },
      { channelType: 'Channel::LineChannel', name: 'Line' },
      { channelType: 'Channel::Whatsapp', name: 'WhatsApp' },
    ];

    const sorted = [...inboxes].sort(helpers.compareInboxes);

    expect(sorted.map(i => i.channelType)).toEqual([
      'Channel::Email',
      'Channel::Whatsapp',

      'Channel::LineChannel',
      'Channel::Unknown',
    ]);
  });

  it('should handle empty array', () => {
    const inboxes = [];
    const sorted = [...inboxes].sort(helpers.compareInboxes);
    expect(sorted).toEqual([]);
  });
});
