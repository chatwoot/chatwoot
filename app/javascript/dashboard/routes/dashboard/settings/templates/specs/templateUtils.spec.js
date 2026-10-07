import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { groupTemplates } from '../templateUtils';

const whatsappInbox = ({
  id,
  name,
  businessAccountId,
  provider = 'whatsapp_cloud',
}) => ({
  id,
  name,
  channel_type: INBOX_TYPES.WHATSAPP,
  provider,
  provider_config: { business_account_id: businessAccountId },
});

describe('#groupTemplates', () => {
  it('uses the newest cache fields when grouping a shared provider template', () => {
    const olderInbox = whatsappInbox({
      id: 1,
      name: 'Older inbox',
      businessAccountId: 'waba-1',
    });
    const newerInbox = whatsappInbox({
      id: 2,
      name: 'Newer inbox',
      businessAccountId: 'waba-1',
    });

    const result = groupTemplates([
      {
        inbox: olderInbox,
        lastUpdatedAt: '2026-08-01T10:00:00.000Z',
        template: {
          id: 'template-1',
          name: 'order_update',
          language: 'en_US',
          status: 'pending',
          components: [{ type: 'BODY', text: 'Old body' }],
        },
      },
      {
        inbox: newerInbox,
        lastUpdatedAt: '2026-08-02T10:00:00.000Z',
        template: {
          id: 'template-1',
          name: 'order_update',
          language: 'en_US',
          status: 'approved',
          components: [{ type: 'BODY', text: 'New body' }],
        },
      },
    ]);

    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      status: 'approved',
      components: [{ type: 'BODY', text: 'New body' }],
      inboxNames: 'Older inbox, Newer inbox',
      lastUpdatedAt: '2026-08-02T10:00:00.000Z',
    });
    expect(result[0].inboxes).toEqual([olderInbox, newerInbox]);
  });

  it('keeps delimiter-containing provider identities separate', () => {
    const result = groupTemplates([
      {
        inbox: whatsappInbox({
          id: 1,
          name: 'Delimiter A',
          businessAccountId: 'account:a',
        }),
        template: {
          id: 'template',
          name: 'delimiter_a',
          language: 'en_US',
        },
      },
      {
        inbox: whatsappInbox({
          id: 2,
          name: 'Delimiter B',
          businessAccountId: 'account',
        }),
        template: {
          id: 'a:template',
          name: 'delimiter_b',
          language: 'en_US',
        },
      },
    ]);

    expect(result).toHaveLength(2);
    expect(result.map(template => template.inboxes)).toEqual([
      [
        whatsappInbox({
          id: 1,
          name: 'Delimiter A',
          businessAccountId: 'account:a',
        }),
      ],
      [
        whatsappInbox({
          id: 2,
          name: 'Delimiter B',
          businessAccountId: 'account',
        }),
      ],
    ]);
  });

  it('scopes templates without provider identities to their inbox and content', () => {
    const result = groupTemplates([
      {
        inbox: whatsappInbox({
          id: 1,
          name: 'First inbox',
          businessAccountId: 'waba-1',
        }),
        template: {
          name: 'shared_name',
          language: 'en_US',
          components: [{ type: 'BODY', text: 'First body' }],
        },
      },
      {
        inbox: whatsappInbox({
          id: 2,
          name: 'Second inbox',
          businessAccountId: 'waba-1',
        }),
        template: {
          name: 'shared_name',
          language: 'en_US',
          components: [{ type: 'BODY', text: 'Second body' }],
        },
      },
    ]);

    expect(result).toHaveLength(2);
    expect(result.map(template => template.searchableContent)).toEqual([
      '[{"type":"BODY","text":"First body"}]',
      '[{"type":"BODY","text":"Second body"}]',
    ]);
  });
});
