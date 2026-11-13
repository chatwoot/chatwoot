import { convertToMp3 } from '../audioConversionUtils';
import { encodePcmToMp3 } from '../mp3Encoder';

vi.mock('../mp3Encoder', () => ({ encodePcmToMp3: vi.fn() }));

const left = new Float32Array([0, 0.5, -0.5]);
const right = new Float32Array([0.1, 0.2, 0.3]);
const audioBlob = { arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)) };

const stubAudioContext = channels => {
  const audioBuffer = {
    numberOfChannels: channels.length,
    sampleRate: 48000,
    getChannelData: index => channels[index],
  };
  vi.stubGlobal(
    'AudioContext',
    vi.fn(() => ({ decodeAudioData: () => Promise.resolve(audioBuffer) }))
  );
};

const stubWorker = respond => {
  const instances = [];
  vi.stubGlobal(
    'Worker',
    class {
      constructor(url, options) {
        this.url = url;
        this.options = options;
        this.terminate = vi.fn();
        instances.push(this);
      }

      postMessage(message) {
        this.message = message;
        queueMicrotask(() => respond(this));
      }
    }
  );
  return instances;
};

describe('convertToMp3', () => {
  beforeEach(() => {
    stubAudioContext([left, right]);
    encodePcmToMp3.mockReturnValue([new Int8Array([1, 2, 3])]);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('encodes in a Web Worker so the main thread is not blocked', async () => {
    const workers = stubWorker(worker =>
      worker.onmessage({ data: { chunks: [new Int8Array([7, 8])] } })
    );

    const mp3 = await convertToMp3(audioBlob);

    expect(workers).toHaveLength(1);
    expect(workers[0].options).toEqual({ type: 'module' });
    expect(workers[0].message).toEqual({
      channelData: [left, right],
      sampleRate: 48000,
      bitrate: 128,
    });
    expect(workers[0].terminate).toHaveBeenCalled();
    expect(encodePcmToMp3).not.toHaveBeenCalled();
    expect(mp3.type).toBe('audio/mp3');
    expect(mp3.size).toBe(2);
  });

  it('encodes on the main thread when Web Workers are not available', async () => {
    vi.stubGlobal('Worker', undefined);

    const mp3 = await convertToMp3(audioBlob);

    expect(encodePcmToMp3).toHaveBeenCalledWith([left, right], 48000, 128);
    expect(mp3.size).toBe(3);
  });

  it('encodes on the main thread when the worker fails to load', async () => {
    const workers = stubWorker(worker => worker.onerror(new Event('error')));

    const mp3 = await convertToMp3(audioBlob);

    expect(workers[0].terminate).toHaveBeenCalled();
    expect(encodePcmToMp3).toHaveBeenCalledWith([left, right], 48000, 128);
    expect(mp3.size).toBe(3);
  });

  it('rejects when the encoder reports an error', async () => {
    stubWorker(worker => worker.onmessage({ data: { error: 'boom' } }));

    await expect(convertToMp3(audioBlob)).rejects.toThrow(
      'Conversion to MP3 failed.'
    );
    expect(encodePcmToMp3).not.toHaveBeenCalled();
  });
});
