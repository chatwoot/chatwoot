import { mount, flushPromises } from '@vue/test-utils';
import CallWaitingSettings from '../CallWaitingSettings.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';

const { dispatch, alert } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('vuex', async importOriginal => ({
  ...(await importOriginal()),
  useStore: () => ({ dispatch }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: alert }));

const inbox = {
  id: 387,
  call_join_beep_enabled: true,
  call_waiting_audio_url: '/music.mp3',
};

const mountComponent = overrides =>
  mount(CallWaitingSettings, {
    props: { inbox: { ...inbox, ...overrides } },
    global: {
      stubs: {
        Spinner: true,
        Icon: true,
        SettingsToggleSection: {
          props: ['modelValue', 'header', 'description', 'hideToggle'],
          template: '<section><slot name="editor" /></section>',
        },
      },
    },
  });

describe('CallWaitingSettings', () => {
  beforeEach(() => vi.clearAllMocks());

  it('uploads the chosen audio file and clears the input for the next pick', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent();
    const input = wrapper.find('input[type="file"]');
    const file = new File(['music'], 'music.mp3', { type: 'audio/mpeg' });
    Object.defineProperty(input.element, 'files', {
      value: [file],
      configurable: true,
    });

    await input.trigger('change');

    expect(dispatch).toHaveBeenCalledWith('inboxes/uploadCallWaitingAudio', {
      id: 387,
      file,
    });
    expect(input.element.value).toBe('');
  });

  it('plays the saved audio and removes it on request', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent();
    expect(wrapper.find('audio').attributes('src')).toBe('/music.mp3');

    wrapper.findAllComponents(NextButton)[1].vm.$emit('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/removeCallWaitingAudio', {
      id: 387,
    });
  });

  it('offers only an upload when no audio is saved', () => {
    const wrapper = mountComponent({ call_waiting_audio_url: null });

    expect(wrapper.find('audio').exists()).toBe(false);
    expect(wrapper.findAllComponents(NextButton)).toHaveLength(1);
  });

  it('restores the join beep toggle after a failed update', async () => {
    dispatch.mockRejectedValue(new Error('Update failed'));
    const wrapper = mountComponent();
    const beep = wrapper.findAllComponents(SettingsToggleSection)[1];

    beep.vm.$emit('update:modelValue', false);
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallJoinBeep', {
      id: 387,
      enabled: false,
    });
    expect(beep.props('modelValue')).toBe(true);
    expect(alert).toHaveBeenCalled();
  });
});
