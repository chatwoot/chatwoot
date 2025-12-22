import { getters } from '../../inboxes';
import inboxList from './fixtures';
import { templates } from './templateFixtures';

describe('#getters', () => {
  it('getInboxes', () => {
    const state = {
      records: inboxList,
    };
    expect(getters.getInboxes(state)).toEqual(inboxList);
  });

  it('getWebsiteInboxes', () => {
    const state = { records: inboxList };
    expect(getters.getWebsiteInboxes(state).length).toEqual(3);
  });

  it('getTwilioInboxes', () => {
    const state = { records: inboxList };
    expect(getters.getTwilioInboxes(state).length).toEqual(1);
  });

  it('getSMSInboxes', () => {
    const state = { records: inboxList };
    expect(getters.getSMSInboxes(state).length).toEqual(2);
  });

  it('dialogFlowEnabledInboxes', () => {
    const state = { records: inboxList };
    expect(getters.dialogFlowEnabledInboxes(state).length).toEqual(8);
  });

  it('getInbox', () => {
    const state = {
      records: inboxList,
    };
    expect(getters.getInbox(state)(1)).toEqual({
      id: 1,
      channel_id: 1,
      name: 'Test FacebookPage 1',
      channel_type: 'Channel::FacebookPage',
      avatar_url: 'random_image.png',
      page_id: '12345',
      widget_color: null,
      website_token: null,
      enable_auto_assignment: true,
      instagram_id: 123456789,
    });
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isFetchingItem: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isFetchingItem: false,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });

  it('getFacebookInboxByInstagramId', () => {
    const state = { records: inboxList };
    expect(getters.getFacebookInboxByInstagramId(state)(123456789)).toEqual({
      id: 1,
      channel_id: 1,
      name: 'Test FacebookPage 1',
      channel_type: 'Channel::FacebookPage',
      avatar_url: 'random_image.png',
      page_id: '12345',
      widget_color: null,
      website_token: null,
      enable_auto_assignment: true,
      instagram_id: 123456789,
    });
  });

  it('getInstagramInboxByInstagramId', () => {
    const state = { records: inboxList };
    expect(getters.getInstagramInboxByInstagramId(state)(123456789)).toEqual({
      id: 7,
      channel_id: 7,
      name: 'Test Instagram 1',
      channel_type: 'Channel::Instagram',
      instagram_id: 123456789,
      provider: 'default',
    });
  });

  it('getTiktokInboxByBusinessId', () => {
    const state = { records: inboxList };
    expect(getters.getTiktokInboxByBusinessId(state)(123456789)).toEqual({
      id: 8,
      channel_id: 8,
      name: 'Test TikTok 1',
      channel_type: 'Channel::Tiktok',
      business_id: 123456789,
      provider: 'default',
    });
  });

  describe('getFilteredWhatsAppTemplates', () => {
    it('returns empty array when inbox not found', () => {
      const state = { records: [] };
      expect(getters.getFilteredWhatsAppTemplates(state)(999)).toEqual([]);
    });

    it('returns empty array when templates is null or undefined', () => {
      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: null,
            additional_attributes: { message_templates: undefined },
          },
        ],
      };
      expect(getters.getFilteredWhatsAppTemplates(state)(1)).toEqual([]);
    });

    it('returns empty array when templates is not an array', () => {
      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: 'invalid',
            additional_attributes: {},
          },
        ],
      };
      expect(getters.getFilteredWhatsAppTemplates(state)(1)).toEqual([]);
    });

    it('filters out templates without required properties', () => {
      const invalidTemplates = [
        { name: 'incomplete_template' }, // missing status and components
        { status: 'approved' }, // missing name and components
        { name: 'another_incomplete', status: 'approved' }, // missing components
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: invalidTemplates,
          },
        ],
      };
      expect(getters.getFilteredWhatsAppTemplates(state)(1)).toEqual([]);
    });

    it('filters out non-approved templates', () => {
      const mixedStatusTemplates = [
        {
          name: 'pending_template',
          status: 'pending',
          components: [{ type: 'BODY', text: 'Test' }],
        },
        {
          name: 'rejected_template',
          status: 'rejected',
          components: [{ type: 'BODY', text: 'Test' }],
        },
        {
          name: 'approved_template',
          status: 'approved',
          components: [{ type: 'BODY', text: 'Test' }],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: mixedStatusTemplates,
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('approved_template');
    });

    it('filters out interactive templates (LIST, PRODUCT, CATALOG)', () => {
      const interactiveTemplates = [
        {
          name: 'list_template',
          status: 'approved',
          components: [
            { type: 'BODY', text: 'Choose an option' },
            { type: 'LIST', sections: [] },
          ],
        },
        {
          name: 'product_template',
          status: 'approved',
          components: [
            { type: 'BODY', text: 'Product info' },
            { type: 'PRODUCT', catalog_id: '123' },
          ],
        },
        {
          name: 'catalog_template',
          status: 'approved',
          components: [
            { type: 'BODY', text: 'Catalog' },
            { type: 'CATALOG', thumbnail_product_retailer_id: '123' },
          ],
        },
        {
          name: 'regular_template',
          status: 'approved',
          components: [{ type: 'BODY', text: 'Regular message' }],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: interactiveTemplates,
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('regular_template');
    });

    it('filters out location templates', () => {
      const locationTemplates = [
        {
          name: 'location_template',
          status: 'approved',
          components: [
            { type: 'HEADER', format: 'LOCATION' },
            { type: 'BODY', text: 'Location message' },
          ],
        },
        {
          name: 'regular_template',
          status: 'approved',
          components: [
            { type: 'HEADER', format: 'TEXT', text: 'Header' },
            { type: 'BODY', text: 'Regular message' },
          ],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: locationTemplates,
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('regular_template');
    });

    it('filters out authentication templates', () => {
      const authenticationTemplates = [
        {
          name: 'auth_template',
          status: 'approved',
          category: 'AUTHENTICATION',
          components: [
            { type: 'BODY', text: 'Your verification code is {{1}}' },
          ],
        },
        {
          name: 'regular_template',
          status: 'approved',
          category: 'MARKETING',
          components: [{ type: 'BODY', text: 'Regular message' }],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: authenticationTemplates,
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('regular_template');
    });

    it('returns valid templates from fixture data', () => {
      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: templates,
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);

      // All templates in fixtures should be approved and valid
      expect(result.length).toBeGreaterThan(0);

      // Verify all returned templates are approved
      result.forEach(template => {
        expect(template.status).toBe('approved');
        expect(template.components).toBeDefined();
        expect(Array.isArray(template.components)).toBe(true);
      });

      // Verify specific templates from fixtures are included
      const templateNames = result.map(t => t.name);
      expect(templateNames).toContain('sample_flight_confirmation');
      expect(templateNames).toContain('sample_issue_resolution');
      expect(templateNames).toContain('sample_shipping_confirmation');
      expect(templateNames).toContain('no_variable_template');
      expect(templateNames).toContain('order_confirmation');
    });

    it('prioritizes message_templates over additional_attributes.message_templates', () => {
      const primaryTemplates = [
        {
          name: 'primary_template',
          status: 'approved',
          components: [{ type: 'BODY', text: 'Primary' }],
        },
      ];

      const fallbackTemplates = [
        {
          name: 'fallback_template',
          status: 'approved',
          components: [{ type: 'BODY', text: 'Fallback' }],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: primaryTemplates,
            additional_attributes: {
              message_templates: fallbackTemplates,
            },
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('primary_template');
    });

    it('falls back to additional_attributes.message_templates when message_templates is null', () => {
      const fallbackTemplates = [
        {
          name: 'fallback_template',
          status: 'approved',
          components: [{ type: 'BODY', text: 'Fallback' }],
        },
      ];

      const state = {
        records: [
          {
            id: 1,
            channel_type: 'Channel::Whatsapp',
            message_templates: null,
            additional_attributes: {
              message_templates: fallbackTemplates,
            },
          },
        ],
      };

      const result = getters.getFilteredWhatsAppTemplates(state)(1);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('fallback_template');
    });
  });
});
