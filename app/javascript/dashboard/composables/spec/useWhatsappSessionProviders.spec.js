import { describe, expect, it, vi, beforeEach } from 'vitest';
import { useWhatsappSessionProviders } from '../useWhatsappSessionProviders';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';

vi.mock('dashboard/api/channel/whatsappChannel', () => ({
  default: { getSessionProviders: vi.fn() },
}));

const CATALOG = [
  { key: 'native', creatable: false, fields: [] },
  { key: 'uazapi', creatable: true, fields: [{ name: 'token' }] },
  { key: 'baileys', legacy: true, creatable: false, fields: [] },
];

describe('useWhatsappSessionProviders', () => {
  beforeEach(() => vi.clearAllMocks());

  it('exposes the catalog the server serves', async () => {
    WhatsappChannel.getSessionProviders.mockResolvedValue({
      data: { payload: CATALOG },
    });

    const { providers, descriptorFor, creatableProviders, fetchProviders } =
      useWhatsappSessionProviders();
    await fetchProviders();

    expect(providers.value).toHaveLength(3);
    expect(descriptorFor('uazapi').fields).toEqual([{ name: 'token' }]);
    expect(creatableProviders.value.map(p => p.key)).toEqual(['uazapi']);
  });

  // The catalog is what the picker offers, so a failed fetch must offer nothing rather
  // than a provider the server would then refuse on create.
  it('offers nothing when the catalog cannot be read', async () => {
    WhatsappChannel.getSessionProviders.mockRejectedValue(new Error('boom'));

    const { providers, creatableProviders, isFetching, fetchProviders } =
      useWhatsappSessionProviders();
    await fetchProviders();

    expect(providers.value).toEqual([]);
    expect(creatableProviders.value).toEqual([]);
    expect(isFetching.value).toBe(false);
  });

  it('offers nothing when the response carries no payload', async () => {
    WhatsappChannel.getSessionProviders.mockResolvedValue({ data: {} });

    const { providers, fetchProviders } = useWhatsappSessionProviders();
    await fetchProviders();

    expect(providers.value).toEqual([]);
  });
});
