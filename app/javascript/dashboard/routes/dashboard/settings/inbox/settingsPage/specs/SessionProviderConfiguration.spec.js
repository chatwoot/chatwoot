import { describe, it, expect, beforeEach, vi } from 'vitest';
import { defineComponent, nextTick } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import SessionProviderConfiguration from '../SessionProviderConfiguration.vue';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';

vi.mock('dashboard/api/channel/whatsappChannel', () => ({
  default: { getSessionProviders: vi.fn() },
}));

const mockDispatch = vi.fn();
const mockKnownKeys = new Set();
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: mockDispatch }) }));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return {
    ...actual,
    useI18n: () => ({ t: key => key, te: key => mockKnownKeys.has(key) }),
  };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const stub = name =>
  defineComponent({ name, template: `<div class="${name}-stub" />` });

const FIELDS = [
  {
    name: 'base_url',
    type: 'url',
    required: true,
    default: null,
    secret: false,
  },
  {
    name: 'token',
    type: 'password',
    required: true,
    default: null,
    secret: true,
  },
  {
    name: 'proxy_url',
    type: 'password',
    required: false,
    default: null,
    secret: false,
  },
  {
    name: 'mark_as_read',
    type: 'boolean',
    required: false,
    default: true,
    secret: false,
  },
];

const catalog = ({ beta }) => [
  { key: 'uazapi', creatable: true, beta, legacy: false, fields: FIELDS },
];

const INBOX = {
  id: 7,
  provider: 'uazapi',
  name: 'Suporte',
  // The server never serves the token back, which is what the save path has to survive.
  provider_config: { base_url: 'https://uaz.example', mark_as_read: true },
};

const mountPage = async ({ beta = true, inbox = INBOX } = {}) => {
  WhatsappChannel.getSessionProviders.mockResolvedValue({
    data: { payload: catalog({ beta }) },
  });

  const wrapper = mount(SessionProviderConfiguration, {
    props: { inbox },
    global: {
      stubs: {
        WhatsappLinkDeviceModal: stub('WhatsappLinkDeviceModal'),
        InboxName: stub('InboxName'),
        // Rendered rather than stubbed away: the badge lives in its slot.
        SettingsSection: defineComponent({
          name: 'SettingsSection',
          inheritAttrs: false,
          template: '<div class="SettingsSection-stub"><slot /></div>',
        }),
        NextButton: stub('NextButton'),
        Switch: stub('Switch'),
        // Its own subject, with its own spec.
        WhatsappHistorySync: stub('WhatsappHistorySync'),
        'woot-input': stub('woot-input'),
      },
    },
  });

  await flushPromises();
  await nextTick();
  return wrapper;
};

describe('SessionProviderConfiguration', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockKnownKeys.clear();
  });

  // Whoever inherits an inbox never saw the picker, so the beta warning has to survive
  // on the page they manage it from.
  it('badges an inbox whose provider the catalog reports as beta', async () => {
    const wrapper = await mountPage({ beta: true });

    expect(wrapper.findComponent({ name: 'Label' }).exists()).toBe(true);
  });

  it('drops the badge once the provider leaves beta', async () => {
    const wrapper = await mountPage({ beta: false });

    expect(wrapper.findComponent({ name: 'Label' }).exists()).toBe(false);
  });

  // A secret is never served back, so its input starts empty. Saving that empty input
  // would replace the stored credential with '' and silently disconnect the inbox.
  it('leaves an untouched secret alone instead of clearing it', async () => {
    const wrapper = await mountPage();
    const token = FIELDS.find(field => field.secret);

    await wrapper.vm.save(token);

    expect(mockDispatch).not.toHaveBeenCalled();
  });

  // The switch has already moved by the time the save fails, so leaving it there shows a
  // setting the server never took -- and the next change event needs a different value,
  // so retrying the one that failed would mean toggling away and back.
  it('puts a preference switch back when the save is refused', async () => {
    const wrapper = await mountPage();
    const preference = FIELDS.find(field => field.type === 'boolean');
    mockDispatch.mockRejectedValueOnce(new Error('refused'));
    wrapper.vm.values[preference.name] = false;

    await wrapper.vm.save(preference);

    expect(wrapper.vm.values[preference.name]).toBe(true);
  });

  it('says why the server refused a save', async () => {
    const wrapper = await mountPage();
    const proxy = FIELDS.find(field => field.name === 'proxy_url');
    mockDispatch.mockRejectedValueOnce(
      new Error('Provider config Invalid configuration for: proxy_url')
    );
    wrapper.vm.values.proxy_url = 'ftp://proxy.example:21';

    await wrapper.vm.save(proxy);

    expect(mockAlert).toHaveBeenCalledWith(
      'Provider config Invalid configuration for: proxy_url'
    );
  });

  it('falls back to the generic message when the server gave no reason', async () => {
    const wrapper = await mountPage();
    const proxy = FIELDS.find(field => field.name === 'proxy_url');
    mockDispatch.mockRejectedValueOnce(new Error(''));

    await wrapper.vm.save(proxy);

    expect(mockAlert).toHaveBeenCalledWith('INBOX_MGMT.EDIT.API.ERROR_MESSAGE');
  });

  it('keeps what was typed into a text field when the save is refused', async () => {
    const wrapper = await mountPage();
    const url = FIELDS.find(field => field.type === 'url');
    mockDispatch.mockRejectedValueOnce(new Error('refused'));
    wrapper.vm.values[url.name] = 'https://moved.example';

    await wrapper.vm.save(url);

    expect(wrapper.vm.values[url.name]).toBe('https://moved.example');
  });

  it('sends a secret the operator actually typed', async () => {
    const wrapper = await mountPage();
    const token = FIELDS.find(field => field.secret);
    wrapper.vm.values[token.name] = 'new-token';

    await wrapper.vm.save(token);

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: INBOX.id,
      formData: false,
      channel: {
        provider_config: { ...INBOX.provider_config, token: 'new-token' },
      },
    });
  });

  // An optional field that is not a secret is served back, so the page shows it and an
  // emptied input is a real value: that is how a proxy is taken away.
  it('shows an optional field the inbox has and clears it when emptied', async () => {
    const wrapper = await mountPage({
      inbox: {
        ...INBOX,
        provider_config: {
          ...INBOX.provider_config,
          proxy_url: 'socks5://u:p@proxy.example:1080',
        },
      },
    });
    const proxy = FIELDS.find(field => field.name === 'proxy_url');
    expect(wrapper.vm.values.proxy_url).toBe('socks5://u:p@proxy.example:1080');
    wrapper.vm.values.proxy_url = '';

    await wrapper.vm.save(proxy);

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: INBOX.id,
      formData: false,
      channel: {
        provider_config: {
          ...INBOX.provider_config,
          proxy_url: '',
        },
      },
    });
  });

  it('explains a field with its description when it has one', async () => {
    const key = 'INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.PROXY_URL';
    mockKnownKeys.add(`${key}.DESCRIPTION`);
    const wrapper = await mountPage();
    const proxy = FIELDS.find(field => field.name === 'proxy_url');
    const token = FIELDS.find(field => field.name === 'token');

    expect(wrapper.vm.fieldHint(proxy)).toBe(`${key}.DESCRIPTION`);
    expect(wrapper.vm.fieldHint(token)).toBe(
      'INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.TOKEN.PLACEHOLDER'
    );
  });
});
