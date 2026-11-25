import { describe, it, expect, vi, afterEach } from 'vitest';
import { convertAudio, downmixToMono } from '../audioConversionUtils';

const SAMPLE_RATE = 44100;

// What AudioContext#decodeAudioData hands back, with one Float32Array per channel.
const fakeAudioBuffer = channels => ({
  numberOfChannels: channels.length,
  length: channels[0].length,
  sampleRate: SAMPLE_RATE,
  getChannelData: index => channels[index],
});

const sine = (length, phase = 0) =>
  Float32Array.from({ length }, (_, i) =>
    Math.sin((2 * Math.PI * 440 * i) / SAMPLE_RATE + phase)
  );

const stubDecodedAudio = audioBuffer => {
  vi.stubGlobal(
    'AudioContext',
    class {
      // eslint-disable-next-line class-methods-use-this
      decodeAudioData() {
        return Promise.resolve(audioBuffer);
      }
    }
  );
};

const recordedBlob = type => {
  const blob = new Blob([new Uint8Array(16)], { type });
  if (!blob.arrayBuffer) {
    blob.arrayBuffer = () => Promise.resolve(new ArrayBuffer(16));
  }
  return blob;
};

const readBytes = blob =>
  new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(new Uint8Array(reader.result));
    reader.onerror = () => reject(reader.error);
    reader.readAsArrayBuffer(blob);
  });

// Channel mode lives in the top two bits of the 4th byte of an MPEG audio
// frame header; 0b11 is mono.
const channelModeOfFirstFrame = bytes => {
  const start = bytes.findIndex(
    (byte, i) => byte === 0xff && (bytes[i + 1] & 0xe0) === 0xe0 // eslint-disable-line no-bitwise
  );
  return bytes[start + 3] >> 6; // eslint-disable-line no-bitwise
};

describe('convertAudio to MP3', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  // A two-channel microphone (USB interface, some headsets) decodes to a
  // stereo buffer; both paths below go through the MP3 encoder.
  it.each([
    ['an MP3 recording', 'audio/webm', 'audio/mp3'],
    ['the Safari OGG fallback', 'audio/mp4', 'audio/ogg'],
  ])(
    'encodes a stereo recording as mono MP3 for %s',
    async (_, inputType, format) => {
      const length = SAMPLE_RATE / 2;
      stubDecodedAudio(fakeAudioBuffer([sine(length), sine(length, 1)]));

      const mp3 = await convertAudio(recordedBlob(inputType), format);

      expect(mp3.type).toBe('audio/mp3');
      const bytes = await readBytes(mp3);
      expect(bytes.length).toBeGreaterThan(0);
      expect(channelModeOfFirstFrame(bytes)).toBe(0b11);
    }
  );

  it('carries the recorded sound into the MP3, not silence', async () => {
    const length = SAMPLE_RATE / 2;
    const encode = async channels => {
      stubDecodedAudio(fakeAudioBuffer(channels));
      return readBytes(
        await convertAudio(recordedBlob('audio/webm'), 'audio/mp3')
      );
    };

    const silent = await encode([
      new Float32Array(length),
      new Float32Array(length),
    ]);
    const voiced = await encode([sine(length), sine(length, 1)]);

    expect(voiced).not.toEqual(silent);
  });
});

describe('downmixToMono', () => {
  it('averages every channel into one clipped 16-bit track', () => {
    const left = Float32Array.from([1, 0.5, -1, 0, 1.5]);
    const right = Float32Array.from([-1, 0.5, -1, 0.5, 1.5]);

    const mono = downmixToMono(fakeAudioBuffer([left, right]));

    expect(Array.from(mono)).toEqual([0, 16383, -32768, 8191, 32767]);
  });
});
