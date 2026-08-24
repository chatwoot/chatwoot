import {
  catalogReturnLocation,
  clearCatalogFlow,
  getCatalogFlow,
  saveCatalogFlow,
} from './catalogFlow';

const flow = {
  accountId: '1',
  assistantId: '42',
  providerKey: 'slack',
  installationId: 'installation-1',
  selectedKeys: ['send_message_to_channel'],
  configurations: {},
};

describe('catalogFlow', () => {
  beforeEach(() => window.sessionStorage.clear());

  it('restores only the flow scoped to the account and provider', () => {
    saveCatalogFlow(flow);

    expect(getCatalogFlow('1', 'slack')).toEqual(flow);
    expect(getCatalogFlow('2', 'slack')).toBeNull();
    expect(getCatalogFlow('1', 'linear')).toBeNull();
  });

  it('returns to a fixed catalog route only for the matching installation', () => {
    saveCatalogFlow(flow);

    expect(
      catalogReturnLocation({
        accountId: '1',
        providerKey: 'slack',
        installationId: 'installation-1',
      })
    ).toEqual({
      name: 'captain_tools_catalog_provider',
      params: {
        accountId: '1',
        assistantId: '42',
        providerKey: 'slack',
      },
      query: { installation_id: 'installation-1' },
    });
    expect(
      catalogReturnLocation({
        accountId: '1',
        providerKey: 'slack',
        installationId: 'installation-2',
      })
    ).toBeNull();

    clearCatalogFlow('1', 'slack');
    expect(getCatalogFlow('1', 'slack')).toBeNull();
  });
});
