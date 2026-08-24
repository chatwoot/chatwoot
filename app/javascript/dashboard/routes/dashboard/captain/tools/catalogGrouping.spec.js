import { groupCatalogTools, groupCustomTools } from './catalogGrouping';

describe('catalogGrouping', () => {
  it('groups catalog tools by provider and category with connection state', () => {
    const tools = [
      {
        id: 1,
        source_kind: 'catalog',
        provider_key: 'stripe',
        category_key: 'plans_and_subscriptions',
        title: 'Get subscription status',
        connection_required: false,
      },
      {
        id: 2,
        source_kind: 'catalog',
        provider_key: 'stripe',
        category_key: 'customers',
        title: 'Get current customer',
        connection_required: false,
      },
    ];
    const providers = [
      {
        key: 'stripe',
        name: 'Stripe',
        update_count: 1,
        connection: { connected: true, display_name: 'Acme Billing' },
      },
    ];

    const [group] = groupCatalogTools(tools, providers);

    expect(group).toMatchObject({
      key: 'stripe',
      name: 'Stripe',
      toolCount: 2,
      updateCount: 1,
      connection: { connected: true, display_name: 'Acme Billing' },
    });
    expect(group.categories.map(category => category.name)).toEqual([
      'Plans And Subscriptions',
      'Customers',
    ]);
  });

  it('groups custom and generated tools by normalized hostname', () => {
    const groups = groupCustomTools([
      {
        id: 1,
        source_kind: 'custom',
        endpoint_url: 'https://api.example.com/orders',
      },
      {
        id: 2,
        source_kind: 'generated',
        endpoint_url: 'https://api.example.com/customers',
      },
      { id: 3, source_kind: 'custom', endpoint_url: 'not a url' },
    ]);

    expect(groups).toHaveLength(2);
    expect(
      groups.find(group => group.key === 'api.example.com').tools
    ).toHaveLength(2);
    expect(groups.find(group => group.key === 'custom').name).toBe(
      'Custom tools'
    );
  });
});
