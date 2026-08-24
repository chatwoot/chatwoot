import {
  buildSelections,
  missingRequiredConfiguration,
  requiredScopes,
  updateSelections,
} from './catalogSelection';

const provider = {
  categories: [
    {
      key: 'messaging',
      name: 'Messaging',
      templates: [
        {
          key: 'send_message',
          version: '1.0.0',
          installed: false,
          required_scopes: ['chat:write', 'channels:read'],
          configuration_schema: {
            required: ['channel_id'],
            properties: { channel_id: { type: 'string' } },
          },
        },
        {
          key: 'reply',
          version: '2.0.0',
          installed: true,
          update_available: true,
          installed_configuration: {},
          required_scopes: ['chat:write'],
          configuration_schema: { properties: {} },
        },
      ],
    },
  ],
};

describe('catalogSelection', () => {
  it('builds versioned non-secret installation selections', () => {
    const selections = buildSelections(provider, ['send_message', 'reply'], {
      send_message: { channel_id: 'C012SUPPORT' },
    });

    expect(selections).toEqual([
      {
        template_key: 'send_message',
        template_version: '1.0.0',
        configuration: { channel_id: 'C012SUPPORT' },
      },
    ]);
    expect(requiredScopes(provider.categories[0].templates)).toEqual([
      'channels:read',
      'chat:write',
    ]);
  });

  it('detects missing setup fields and preserves installed configuration for updates', () => {
    const templates = [provider.categories[0].templates[0]];

    expect(missingRequiredConfiguration(templates, {})).toBe(true);
    expect(
      missingRequiredConfiguration(templates, {
        send_message: { channel_id: 'C012SUPPORT' },
      })
    ).toBe(false);
    expect(updateSelections(provider)).toEqual([
      {
        template_key: 'reply',
        template_version: '2.0.0',
        configuration: {},
      },
    ]);
  });
});
