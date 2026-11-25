import { consumePairingRequest } from 'dashboard/helper/whatsappPairingRequest';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { flushPromises, mount } from '@vue/test-utils';
import BaileysWhatsapp from '../BaileysWhatsapp.vue';
import ZapiWhatsapp from '../ZapiWhatsapp.vue';

const mockDispatch = vi.fn();
const mockReplace = vi.fn();
vi.mock('vuex', () => ({
  useStore: () => ({
    dispatch: mockDispatch,
    getters: { 'inboxes/getUIFlags': {} },
  }),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({
    replace: mockReplace,
    currentRoute: { value: { params: { accountId: 1 } } },
  }),
}));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const INBOX = { id: 7, name: 'Vendas', phone_number: '+5511999999999' };

// The two legacy forms convert on their own, outside the catalog-driven session form, so
// each one has to land the inbox on the pairing by itself.
describe('converting to a provider paired by QR', () => {
  beforeEach(() => {
    mockDispatch.mockReset().mockResolvedValue({ id: 7 });
    mockReplace.mockReset();
  });

  it.each([
    ['Baileys', BaileysWhatsapp, 0],
    ['Z-API', ZapiWhatsapp, 3],
  ])(
    '%s lands the inbox on its settings with the pairing open',
    async (_, component, credentialInputs) => {
      const wrapper = mount(component, {
        props: { mode: 'convert', inbox: INBOX },
        global: { mocks: { $t: key => key } },
      });
      const inputs = wrapper.findAll('input');
      await Promise.all(
        inputs
          .slice(2, 2 + credentialInputs)
          .map(input => input.setValue('secret'))
      );

      await wrapper.find('form').trigger('submit');
      await flushPromises();

      expect(mockDispatch).toHaveBeenCalledWith(
        'inboxes/convertProvider',
        expect.objectContaining({ inboxId: 7 })
      );
      expect(mockReplace).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'settings_inbox_show',
          params: { accountId: 1, inboxId: 7 },
        })
      );
      // In memory, not in the URL: a reload or a Back must not bring it back.
      expect(mockReplace.mock.calls[0][0]).not.toHaveProperty('query');
      expect(consumePairingRequest(7)).toBe(true);
    }
  );
});
