import {
  buildSelections,
  installedConfigurations,
  installedTemplateKeys,
  missingRequiredConfiguration,
  requiredScopes,
  selectionChanged,
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
          installed_version: '1.0.0',
          update_available: true,
          installed_configuration: { thread_only: true },
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
      {
        template_key: 'reply',
        template_version: '2.0.0',
        configuration: {},
      },
    ]);
    expect(requiredScopes(provider.categories[0].templates)).toEqual([
      'channels:read',
      'chat:write',
    ]);
  });

  it('detects missing setup fields and restores the installed selection', () => {
    const templates = [provider.categories[0].templates[0]];

    expect(missingRequiredConfiguration(templates, {})).toBe(true);
    expect(
      missingRequiredConfiguration(templates, {
        send_message: { channel_id: 'C012SUPPORT' },
      })
    ).toBe(false);
    expect(installedTemplateKeys(provider)).toEqual(['reply']);
    expect(installedConfigurations(provider)).toEqual({
      reply: { thread_only: true },
    });
  });

  it('detects additions, removals, configuration changes, and catalog updates', () => {
    expect(
      selectionChanged(provider, ['reply'], {
        reply: { thread_only: true },
      })
    ).toBe(true);

    const currentProvider = structuredClone(provider);
    const installedTemplate = currentProvider.categories[0].templates[1];
    installedTemplate.installed_version = installedTemplate.version;
    installedTemplate.update_available = false;

    expect(
      selectionChanged(currentProvider, ['reply'], {
        reply: { thread_only: true },
      })
    ).toBe(false);
    expect(selectionChanged(currentProvider, [], {})).toBe(true);
    expect(
      selectionChanged(currentProvider, ['reply'], {
        reply: { thread_only: false },
      })
    ).toBe(true);
  });
});
