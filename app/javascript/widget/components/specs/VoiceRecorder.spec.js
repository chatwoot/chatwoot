import { shallowMount, flushPromises } from '@vue/test-utils';
import VoiceRecorder from '../VoiceRecorder.vue';

class FakeMediaRecorder extends EventTarget {
  static isTypeSupported = type => type === 'audio/webm';

  constructor(stream, { mimeType }) {
    super();
    this.mimeType = mimeType;
    this.state = 'inactive';
    FakeMediaRecorder.instance = this;
  }

  start() {
    this.state = 'recording';
  }

  // Like the browser: flush the recorded data, then fire `stop`.
  stop() {
    this.state = 'inactive';
    this.dispatchEvent(
      Object.assign(new Event('dataavailable'), { data: new Blob(['audio']) })
    );
    this.dispatchEvent(new Event('stop'));
  }
}

describe('VoiceRecorder', () => {
  let track;
  let originalMediaRecorder;
  let originalMediaDevices;

  const mountRecorder = async () => {
    const wrapper = shallowMount(VoiceRecorder, {
      global: { mocks: { $t: key => key } },
    });
    await flushPromises();
    return wrapper;
  };

  beforeEach(() => {
    track = { stop: vi.fn() };
    originalMediaRecorder = window.MediaRecorder;
    originalMediaDevices = navigator.mediaDevices;
    window.MediaRecorder = FakeMediaRecorder;
    Object.defineProperty(navigator, 'mediaDevices', {
      configurable: true,
      value: {
        getUserMedia: vi.fn().mockResolvedValue({ getTracks: () => [track] }),
      },
    });
  });

  afterEach(() => {
    window.MediaRecorder = originalMediaRecorder;
    Object.defineProperty(navigator, 'mediaDevices', {
      configurable: true,
      value: originalMediaDevices,
    });
  });

  it('emits the recording when the visitor stops it', async () => {
    const wrapper = await mountRecorder();

    await wrapper.findAll('button')[1].trigger('click');

    const [[file]] = wrapper.emitted('finish');
    expect(file.type).toBe('audio/webm');
    expect(file.name).toMatch(/\.webm$/);
    expect(track.stop).toHaveBeenCalled();
  });

  it('does not submit a partial recording after a recorder error', async () => {
    const wrapper = await mountRecorder();
    const error = new Error('Encoder failed');

    FakeMediaRecorder.instance.dispatchEvent(
      Object.assign(new Event('error'), { error })
    );
    FakeMediaRecorder.instance.stop();

    expect(wrapper.emitted('error')).toEqual([[error]]);
    expect(wrapper.emitted('finish')).toBeUndefined();
    expect(track.stop).toHaveBeenCalled();
  });
});
