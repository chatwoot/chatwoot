import { shallowMount, flushPromises } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import InboxesAPI from 'dashboard/api/inboxes';
import CallRecordingSettings from '../CallRecordingSettings.vue';

withFullI18n();

const dispatch = vi.fn();

vi.mock('vuex', () => ({ useStore: () => ({ dispatch }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/inboxes', () => ({
  default: { setCallRecording: vi.fn() },
}));

const mountComponent = (inbox = {}) =>
  shallowMount(CallRecordingSettings, {
    props: { inbox: { id: 7, ...inbox } },
    global: { stubs: { SettingsToggleSection: true, Spinner: true } },
  });

const toggles = wrapper =>
  wrapper.findAllComponents({ name: 'SettingsToggleSection' });

describe('CallRecordingSettings.vue', () => {
  it('treats an inbox that never touched the settings as fully enabled', () => {
    const wrapper = mountComponent();

    expect(toggles(wrapper)).toHaveLength(2);
    expect(toggles(wrapper)[0].props('modelValue')).toBe(true);
    expect(toggles(wrapper)[1].props('modelValue')).toBe(true);
  });

  it('hides the transcription toggle while recording is off', () => {
    const wrapper = mountComponent({ recording_enabled: false });

    expect(toggles(wrapper)).toHaveLength(1);
  });

  it('posts both flags together so neither clobbers the other', async () => {
    InboxesAPI.setCallRecording.mockResolvedValue({});
    const wrapper = mountComponent({ transcription_enabled: false });

    toggles(wrapper)[0].vm.$emit('update:modelValue', false);
    await flushPromises();

    expect(InboxesAPI.setCallRecording).toHaveBeenCalledWith(7, {
      recordingEnabled: false,
      transcriptionEnabled: false,
    });
    expect(dispatch).toHaveBeenCalledWith('inboxes/get', 7);
  });

  it('restores the toggle when the save fails', async () => {
    InboxesAPI.setCallRecording.mockRejectedValue(new Error('network'));
    const wrapper = mountComponent();

    toggles(wrapper)[0].vm.$emit('update:modelValue', false);
    await flushPromises();

    // The server never accepted the change, so both switches must read as before.
    expect(toggles(wrapper)).toHaveLength(2);
    expect(toggles(wrapper)[0].props('modelValue')).toBe(true);
    expect(toggles(wrapper)[1].props('modelValue')).toBe(true);
  });
});
