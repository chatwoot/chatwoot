import { encodeToMP3, convertToMp3 } from '../audioConversionUtils';

const SAMPLE_RATE = 44100;

const buildSineSamples = (length, frequency = 440) => {
  const samples = new Int16Array(length);
  for (let i = 0; i < length; i += 1) {
    samples[i] = Math.round(
      Math.sin((2 * Math.PI * frequency * i) / SAMPLE_RATE) * 0x7fff * 0.5
    );
  }
  return samples;
};

const buildFakeAudioBuffer = (numberOfChannels, length) => {
  const channels = [];
  for (let channel = 0; channel < numberOfChannels; channel += 1) {
    const data = new Float32Array(length);
    for (let i = 0; i < length; i += 1) {
      data[i] = Math.sin((2 * Math.PI * 440 * i) / SAMPLE_RATE) * 0.5;
    }
    channels.push(data);
  }
  return {
    numberOfChannels,
    length,
    sampleRate: SAMPLE_RATE,
    getChannelData: channel => channels[channel],
  };
};

const stubAudioContext = audioBuffer => {
  window.AudioContext = vi.fn().mockImplementation(() => ({
    decodeAudioData: vi.fn().mockResolvedValue(audioBuffer),
  }));
};

describe('#encodeToMP3', () => {
  it('encodes mono samples into a non-empty audio/mp3 blob', () => {
    const samples = buildSineSamples(SAMPLE_RATE);
    const blob = encodeToMP3(1, SAMPLE_RATE, [samples]);

    expect(blob.type).toEqual('audio/mp3');
    expect(blob.size).toBeGreaterThan(0);
  });

  it('encodes stereo samples with separate channel buffers without throwing', () => {
    const left = buildSineSamples(SAMPLE_RATE, 440);
    const right = buildSineSamples(SAMPLE_RATE, 880);
    const blob = encodeToMP3(2, SAMPLE_RATE, [left, right]);

    expect(blob.type).toEqual('audio/mp3');
    expect(blob.size).toBeGreaterThan(0);
  });
});

describe('#convertToMp3', () => {
  const audioBlob = {
    type: 'audio/webm',
    arrayBuffer: async () => new ArrayBuffer(8),
  };

  it.each([1, 2, 6])(
    'downmixes a %i-channel recording to mono and returns an mp3 blob',
    async numberOfChannels => {
      stubAudioContext(buildFakeAudioBuffer(numberOfChannels, SAMPLE_RATE));

      const blob = await convertToMp3(audioBlob);

      expect(blob.type).toEqual('audio/mp3');
      expect(blob.size).toBeGreaterThan(0);
    }
  );

  it('preserves the original error message when decoding fails', async () => {
    window.AudioContext = vi.fn().mockImplementation(() => ({
      decodeAudioData: vi
        .fn()
        .mockRejectedValue(new Error('Unable to decode audio data')),
    }));

    await expect(convertToMp3(audioBlob)).rejects.toThrow(
      'Conversion to MP3 failed: Unable to decode audio data'
    );
  });
});
