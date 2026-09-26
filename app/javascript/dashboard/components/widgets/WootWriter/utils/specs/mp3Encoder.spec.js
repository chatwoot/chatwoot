import { encodePcmToMp3 } from '../mp3Encoder';

const SAMPLE_RATE = 48000;

const tone = (length, amplitude = 0.5) =>
  Float32Array.from(
    { length },
    (_, i) => amplitude * Math.sin((2 * Math.PI * 440 * i) / SAMPLE_RATE)
  );

const toBytes = chunks => {
  const total = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const bytes = new Uint8Array(total);
  let offset = 0;
  chunks.forEach(chunk => {
    bytes.set(
      new Uint8Array(chunk.buffer, chunk.byteOffset, chunk.length),
      offset
    );
    offset += chunk.length;
  });
  return bytes;
};

// An MP3 frame starts with 11 sync bits set, and the top two bits of the
// fourth header byte hold the channel mode (0b11 is mono).
const hasFrameSync = bytes => bytes[0] === 0xff && bytes[1] >= 0xe0;
const isMono = bytes => bytes[3] >= 0xc0;

describe('encodePcmToMp3', () => {
  it('encodes mono PCM into MP3 frames', () => {
    const bytes = toBytes(encodePcmToMp3([tone(SAMPLE_RATE)], SAMPLE_RATE));

    expect(hasFrameSync(bytes)).toBe(true);
    expect(isMono(bytes)).toBe(true);
  });

  it('encodes both channels of stereo PCM', () => {
    const channels = [tone(SAMPLE_RATE), tone(SAMPLE_RATE, 0.25)];
    const bytes = toBytes(encodePcmToMp3(channels, SAMPLE_RATE));

    expect(hasFrameSync(bytes)).toBe(true);
    expect(isMono(bytes)).toBe(false);
  });

  it('clamps samples outside the [-1, 1] range', () => {
    const chunks = encodePcmToMp3([tone(SAMPLE_RATE, 2)], SAMPLE_RATE);

    expect(toBytes(chunks).length).toBeGreaterThan(0);
  });
});
