import { consumePairingRequest } from 'dashboard/helper/whatsappPairingRequest';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { flushPromises, mount } from '@vue/test-utils';
import SessionWhatsapp from '../SessionWhatsapp.vue';

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

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const field = (name, type, extra = {}) => ({
  name,
  type,
  required: false,
  default: null,
  secret: false,
  advanced: false,
  ...extra,
});

// What the server answers for `native`, plus two fields that are not in it: a text field
// marked advanced, so the form is shown to follow the attribute rather than the type or a
// field name, and a boolean that is not, so a boolean alone does not hide a field either.
const DESCRIPTOR = {
  key: 'native',
  fields: [
    field('base_url', 'url', { required: true }),
    field('proxy_url', 'password', { advanced: true }),
    field('region', 'string', { advanced: true }),
    field('mark_as_read', 'boolean', { default: true, advanced: true }),
    field('history_sync', 'boolean', { default: false, advanced: true }),
    field('pinned', 'boolean', { default: false }),
  ],
};

const mountForm = (props = {}) =>
  mount(SessionWhatsapp, {
    props: { descriptor: DESCRIPTOR, ...props },
    global: { mocks: { $t: key => key } },
  });

const input = (wrapper, name) =>
  wrapper.find(`input[data-field="${name}"]`).exists() ||
  wrapper.find(`#${name}`).exists();

const advancedToggle = wrapper =>
  wrapper
    .findAll('button')
    .find(b => b.text().includes('INBOX_MGMT.ADD.WHATSAPP.ADVANCED_OPTIONS'));

describe('SessionWhatsapp.vue', () => {
  beforeEach(() => {
    mockDispatch.mockReset();
    mockAlert.mockReset();
    mockReplace.mockReset();
  });

  it('lands a converted inbox on its settings with the pairing open', async () => {
    mockDispatch.mockResolvedValue({ id: 7 });
    const wrapper = mountForm({
      mode: 'convert',
      inbox: {
        id: 7,
        name: 'Vendas',
        phone_number: '+5511999999999',
        provider_config: {},
      },
    });
    await wrapper.find('input[data-field="base_url"]').setValue('https://x.y');

    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith(
      'inboxes/convertProvider',
      expect.objectContaining({ inboxId: 7, provider: 'native' })
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
  });

  it('keeps every field the catalog marks advanced behind the toggle', async () => {
    const wrapper = mountForm();

    expect(input(wrapper, 'base_url')).toBe(true);
    expect(input(wrapper, 'pinned')).toBe(true);
    ['proxy_url', 'region', 'mark_as_read', 'history_sync'].forEach(name =>
      expect(input(wrapper, name)).toBe(false)
    );

    await advancedToggle(wrapper).trigger('click');

    ['proxy_url', 'region', 'mark_as_read', 'history_sync'].forEach(name =>
      expect(input(wrapper, name)).toBe(true)
    );
  });

  it('opens the advanced options by itself when one of them is already set', async () => {
    const wrapper = mountForm({
      inbox: { id: 7, provider_config: { proxy_url: 'socks5://p:1080' } },
    });
    await flushPromises();

    expect(input(wrapper, 'proxy_url')).toBe(true);
    expect(advancedToggle(wrapper)).toBeUndefined();
  });

  it('opens them when the catalog lands after the form is on screen', async () => {
    const wrapper = mountForm({
      descriptor: { key: 'native', fields: [] },
      inbox: { id: 7, provider_config: { proxy_url: 'socks5://p:1080' } },
    });
    await wrapper.setProps({ descriptor: DESCRIPTOR });
    await flushPromises();

    expect(input(wrapper, 'proxy_url')).toBe(true);
  });

  it('opens them for a preference set away from its default', async () => {
    const wrapper = mountForm({
      inbox: { id: 7, provider_config: { history_sync: true } },
    });
    await flushPromises();

    expect(input(wrapper, 'history_sync')).toBe(true);
  });

  it('leaves them closed when everything advanced holds its default', async () => {
    const wrapper = mountForm({
      inbox: {
        id: 7,
        provider_config: { proxy_url: '', mark_as_read: true },
      },
    });
    await flushPromises();

    expect(input(wrapper, 'proxy_url')).toBe(false);
    expect(advancedToggle(wrapper)).toBeDefined();
  });

  it('sends what was typed into an advanced field with the rest of the config', async () => {
    mockDispatch.mockResolvedValue({ id: 9 });
    const wrapper = mountForm();
    await wrapper.find('input[type="text"]').setValue('Caixa');
    await wrapper.findAll('input[type="text"]')[1].setValue('+5511999999999');
    await wrapper.find('input[data-field="base_url"]').setValue('https://x.y');
    await advancedToggle(wrapper).trigger('click');
    await wrapper
      .find('input[data-field="proxy_url"]')
      .setValue('http://u:p@proxy:3128');

    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith(
      'inboxes/createChannel',
      expect.objectContaining({
        channel: expect.objectContaining({
          provider_config: expect.objectContaining({
            proxy_url: 'http://u:p@proxy:3128',
          }),
        }),
      })
    );
  });

  it('keeps a typed proxy on screen when the server refuses it', async () => {
    mockDispatch.mockRejectedValue(new Error('invalid proxy_url'));
    const wrapper = mountForm();
    await wrapper.find('input[type="text"]').setValue('Caixa');
    await wrapper.findAll('input[type="text"]')[1].setValue('+5511999999999');
    await wrapper.find('input[data-field="base_url"]').setValue('https://x.y');
    await advancedToggle(wrapper).trigger('click');
    await wrapper.find('input[data-field="proxy_url"]').setValue('ftp://h');

    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith('invalid proxy_url');
    expect(wrapper.find('input[data-field="proxy_url"]').element.value).toBe(
      'ftp://h'
    );
  });
});
