import { encodePcmToMp3 } from '../mp3Encoder';

vi.mock('../mp3Encoder', () => ({ encodePcmToMp3: vi.fn() }));

const message = {
  channelData: [new Float32Array([0, 0.5])],
  sampleRate: 48000,
  bitrate: 128,
};

describe('mp3Encoder.worker', () => {
  let postMessage;

  beforeAll(async () => {
    await import('../mp3Encoder.worker');
  });

  beforeEach(() => {
    postMessage = vi
      .spyOn(globalThis, 'postMessage')
      .mockImplementation(() => {});
  });

  it('posts the encoded chunks back and transfers their buffers', () => {
    const chunk = new Int8Array([1, 2, 3]);
    encodePcmToMp3.mockReturnValue([chunk]);

    globalThis.onmessage({ data: message });

    expect(encodePcmToMp3).toHaveBeenCalledWith(
      message.channelData,
      48000,
      128
    );
    expect(postMessage).toHaveBeenCalledWith({ chunks: [chunk] }, [
      chunk.buffer,
    ]);
  });

  it('posts the error message back when encoding fails', () => {
    encodePcmToMp3.mockImplementation(() => {
      throw new Error('boom');
    });

    globalThis.onmessage({ data: message });

    expect(postMessage).toHaveBeenCalledWith({ error: 'boom' });
  });
});
