import { mount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import { transcribeAudioAPI } from 'widget/api/conversation';
import ChatInputWrap from '../ChatInputWrap.vue';
import VoiceRecorder from '../VoiceRecorder.vue';

vi.mock('widget/api/conversation', () => ({ transcribeAudioAPI: vi.fn() }));
vi.mock('widget/composables/useAttachments', () => ({
  useAttachments: () => ({
    canHandleAttachments: false,
    shouldShowEmojiPicker: false,
    hasEmojiPickerEnabled: false,
    canTranscribeAudio: true,
  }),
}));

describe('ChatInputWrap', () => {
  let wrapper;

  afterEach(() => {
    wrapper.unmount();
  });

  it.each([
    ['fails', () => Promise.reject(new Error('Unavailable'))],
    ['is empty', () => Promise.resolve({ data: { transcription: ' ' } })],
    ['succeeds', () => Promise.resolve({ data: { transcription: 'Hello' } })],
  ])(
    'returns focus to the composer when transcription %s',
    async (_, transcribe) => {
      transcribeAudioAPI.mockImplementation(transcribe);
      const store = createStore({
        getters: {
          'appConfig/getWidgetColor': () => '#000000',
          'appConfig/getIsWidgetOpen': () => true,
          'appConfig/getShouldShowEmojiPicker': () => false,
        },
      });
      wrapper = mount(ChatInputWrap, {
        attachTo: document.body,
        global: {
          plugins: [store],
          mocks: { $t: key => key },
          stubs: { VoiceRecorder: true, FluentIcon: true },
        },
      });

      await wrapper
        .find('[aria-label="VOICE_RECORDER.START"]')
        .trigger('click');
      wrapper
        .findComponent(VoiceRecorder)
        .vm.$emit('finish', new File(['audio'], 'speech.webm'));
      await flushPromises();

      expect(document.activeElement).toBe(wrapper.find('textarea').element);
    }
  );
});
