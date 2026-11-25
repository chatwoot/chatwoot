import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ReplyBottomPanel from './ReplyBottomPanel.vue';

const buildStore = ({ voiceRecorderEnabled = true } = {}) =>
  createStore({
    getters: {
      getCurrentAccountId: () => 1,
      getUISettings: () => ({}),
      'accounts/isFeatureEnabledonAccount': () => () => voiceRecorderEnabled,
      'integrations/getUIFlags': () => ({ isFetching: false }),
    },
  });

const mountWith = ({ voiceRecorderEnabled, ...props } = {}) =>
  shallowMount(ReplyBottomPanel, {
    props: {
      conversationId: 1,
      portalSlug: 'handbook',
      showAudioRecorder: true,
      ...props,
    },
    global: {
      plugins: [buildStore({ voiceRecorderEnabled })],
      mocks: { $t: key => key },
    },
  });

describe('ReplyBottomPanel', () => {
  describe.each([
    ['Line', { channel_type: 'Channel::Line' }],
    ['TikTok', { channel_type: 'Channel::Tiktok' }],
  ])('%s', (_name, inbox) => {
    it('hides the voice recorder on a reply, which the channel cannot carry', () => {
      const wrapper = mountWith({ inbox });

      expect(wrapper.vm.showAudioRecorderButton).toBe(false);
    });

    it('offers the voice recorder on a private note, which stays internal', () => {
      const wrapper = mountWith({ inbox, isOnPrivateNote: true });

      expect(wrapper.vm.showAudioRecorderButton).toBe(true);
    });
  });

  it('hides the voice recorder while the editor is disabled', () => {
    const wrapper = mountWith({
      inbox: { channel_type: 'Channel::WebWidget' },
      isOnPrivateNote: true,
      isEditorDisabled: true,
    });

    expect(wrapper.vm.showAudioRecorderButton).toBe(false);
  });

  it('stays behind the account feature flag, note or not', () => {
    const wrapper = mountWith({
      inbox: { channel_type: 'Channel::WebWidget' },
      isOnPrivateNote: true,
      voiceRecorderEnabled: false,
    });

    expect(wrapper.vm.showAudioRecorderButton).toBe(false);
  });

  it('offers the play/stop control while a note is being recorded', () => {
    const wrapper = mountWith({
      inbox: { channel_type: 'Channel::Line' },
      isOnPrivateNote: true,
      isRecordingAudio: true,
    });

    expect(wrapper.vm.showAudioPlayStopButton).toBe(true);
  });
});
