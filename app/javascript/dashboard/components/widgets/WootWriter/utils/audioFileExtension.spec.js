import { describe, expect, it } from 'vitest';
import { getAudioFileExtension } from './audioFileExtension';

describe('getAudioFileExtension', () => {
  it.each([
    ['audio/ogg', 'ogg'],
    ['audio/mp3', 'mp3'],
    ['audio/mpeg', 'mp3'],
    ['audio/wav', 'wav'],
    ['audio/webm', 'webm'],
  ])('maps %s to .%s', (mimeType, ext) => {
    expect(getAudioFileExtension(mimeType)).toBe(ext);
  });

  it.each([
    ['audio/ogg;codecs=opus', 'ogg'],
    ['audio/ogg; codecs=opus', 'ogg'],
    ['audio/webm;codecs=opus', 'webm'],
    ['AUDIO/OGG; CODECS=OPUS', 'ogg'],
  ])('ignores codec parameters in %s', (mimeType, ext) => {
    expect(getAudioFileExtension(mimeType)).toBe(ext);
  });

  it.each([['audio/mp4'], [''], [undefined]])(
    'falls back to mp3 for %s',
    mimeType => {
      expect(getAudioFileExtension(mimeType)).toBe('mp3');
    }
  );
});
