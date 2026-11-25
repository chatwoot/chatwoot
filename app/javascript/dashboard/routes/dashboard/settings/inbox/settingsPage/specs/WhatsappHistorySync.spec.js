import { describe, it, expect, beforeEach, vi } from 'vitest';
import { defineComponent, nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import WhatsappHistorySync from '../WhatsappHistorySync.vue';
const mockDispatch = vi.fn();
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: mockDispatch }) }));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const stub = name =>
  defineComponent({ name, template: `<div class="${name}-stub" />` });

const INBOX = {
  id: 7,
  provider: 'baileys',
  name: 'Suporte',
  capabilities: ['history_sync'],
  provider_config: { history_sync: false },
};

const mountSection = async (inbox = INBOX) => {
  const wrapper = mount(WhatsappHistorySync, {
    props: { inbox },
    global: {
      stubs: {
        SettingsSection: defineComponent({
          name: 'SettingsSection',
          inheritAttrs: false,
          template: '<div class="SettingsSection-stub"><slot /></div>',
        }),
        Switch: stub('Switch'),
        Input: stub('Input'),
        NextButton: stub('NextButton'),
      },
    },
  });

  await nextTick();
  return wrapper;
};

describe('WhatsappHistorySync', () => {
  beforeEach(() => vi.clearAllMocks());

  // Gated on the capability, not on the provider name: it is offered by a session
  // provider and by the legacy one alike, and by neither of the cloud ones.
  it('renders nothing for a provider that cannot fetch history', async () => {
    const wrapper = await mountSection({ ...INBOX, capabilities: [] });

    expect(wrapper.find('.SettingsSection-stub').exists()).toBe(false);
  });

  it('renders for a provider that can', async () => {
    const wrapper = await mountSection();

    expect(wrapper.find('.SettingsSection-stub').exists()).toBe(true);
  });

  describe('the standing setting', () => {
    it('saves the operator turning it on', async () => {
      const wrapper = await mountSection();
      wrapper.vm.enabled = true;

      await wrapper.vm.saveSetting();

      expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
        id: INBOX.id,
        formData: false,
        channel: { provider_config: { history_sync: true } },
      });
    });

    // The switch has already moved by the time the save fails, so leaving it there shows
    // a setting the server never took -- and the next change event needs a different
    // value, so retrying the one that failed would mean toggling away and back.
    it('puts the switch back when the save is refused', async () => {
      const wrapper = await mountSection({
        ...INBOX,
        provider_config: { history_sync: true },
      });
      mockDispatch.mockRejectedValueOnce(new Error('refused'));
      wrapper.vm.enabled = false;

      await wrapper.vm.saveSetting();

      expect(wrapper.vm.enabled).toBe(true);
    });
  });

  describe('the history files', () => {
    const NATIVE = {
      ...INBOX,
      provider: 'native',
      provider_config: { history_sync: true },
    };

    // Only the session layer files history messages that wait for their files.
    it('is not offered on the legacy provider that also imports history', async () => {
      const wrapper = await mountSection();

      expect(wrapper.findAll('.SettingsSection-stub')).toHaveLength(1);
    });

    // The point is that the files arrive with no action from anybody, so an inbox that
    // never saved the option shows it on, with the default window.
    it('shows an inbox that never saved the option as fetching, with the default window', async () => {
      const wrapper = await mountSection(NATIVE);

      expect(wrapper.findAll('.SettingsSection-stub')).toHaveLength(2);
      expect(wrapper.vm.fetchMedia).toBe(true);
      expect(wrapper.vm.windowDays).toBe(30);
    });

    it('saves the window with the rest of the config', async () => {
      const wrapper = await mountSection(NATIVE);
      wrapper.vm.windowDays = 7;

      await wrapper.vm.saveWindowDays();

      expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
        id: NATIVE.id,
        formData: false,
        channel: {
          provider_config: { history_sync: true, history_media_days: 7 },
        },
      });
    });

    it('does not send a window that is not a positive whole number', async () => {
      const wrapper = await mountSection(NATIVE);

      await Promise.all(
        [0, -5, '', 2.5].map(days => {
          wrapper.vm.windowDays = days;
          return wrapper.vm.saveWindowDays();
        })
      );

      expect(mockDispatch).not.toHaveBeenCalled();
    });

    it('saves the switch turned off', async () => {
      const wrapper = await mountSection(NATIVE);
      wrapper.vm.fetchMedia = false;

      await wrapper.vm.saveFetchMedia();

      expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
        id: NATIVE.id,
        formData: false,
        channel: {
          provider_config: { history_sync: true, history_media_fetch: false },
        },
      });
    });

    // The switch is saved on click and the inbox reloads with what the server holds; a
    // window typed meanwhile must survive that reload and be what the next save sends.
    it('keeps a window typed while the switch was being saved', async () => {
      const wrapper = await mountSection(NATIVE);
      wrapper.vm.editWindowDays(7);

      await wrapper.setProps({
        inbox: {
          ...NATIVE,
          provider_config: {
            ...NATIVE.provider_config,
            history_media_fetch: false,
          },
        },
      });
      expect(wrapper.vm.windowDays).toBe(7);
      expect(wrapper.vm.fetchMedia).toBe(false);

      await wrapper.vm.saveWindowDays();
      expect(mockDispatch).toHaveBeenLastCalledWith(
        'inboxes/updateInbox',
        expect.objectContaining({
          channel: {
            provider_config: expect.objectContaining({ history_media_days: 7 }),
          },
        })
      );
    });

    // Each save sends the whole config, so a second one sent while the first is still
    // out would carry the switch from before it and turn the fetch back on.
    it('holds a second save until the first one comes back', async () => {
      let finish;
      mockDispatch.mockReturnValueOnce(
        new Promise(resolve => {
          finish = resolve;
        })
      );
      const wrapper = await mountSection(NATIVE);
      wrapper.vm.fetchMedia = false;
      const first = wrapper.vm.saveFetchMedia();
      wrapper.vm.windowDays = 7;

      wrapper.vm.saveWindowDays();
      expect(mockDispatch).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.windowDays).toBe(30);

      finish();
      await first;
      wrapper.vm.windowDays = 7;
      await wrapper.vm.saveWindowDays();
      expect(mockDispatch).toHaveBeenCalledTimes(2);
    });
  });
});
