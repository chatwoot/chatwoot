/* eslint-disable no-bitwise */
import { describe, it, expect, vi } from 'vitest';
import { remuxWebmToOgg } from '../webmOpusToOgg';

/**
 * Helper: build a Blob from a Uint8Array.
 * jsdom's Blob may lack .arrayBuffer(), so we polyfill it.
 */
function blobFrom(bytes) {
  const blob = new Blob([bytes], { type: 'audio/webm' });
  if (!blob.arrayBuffer) {
    blob.arrayBuffer = () =>
      new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = () => reject(reader.error);
        reader.readAsArrayBuffer(blob);
      });
  }
  return blob;
}

/**
 * Safely read a Blob's ArrayBuffer (works even if Blob.arrayBuffer is missing in jsdom).
 */
async function readBlobAsArrayBuffer(blob) {
  if (blob.arrayBuffer) {
    return blob.arrayBuffer();
  }
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error);
    reader.readAsArrayBuffer(blob);
  });
}

// --- EBML element helpers (shared across tests) ---

function writeVint(value) {
  // 1-byte VINT for values 0-126
  if (value < 0x7f) return [0x80 | value];
  // 2-byte VINT for values up to 0x3fff
  return [0x40 | ((value >> 8) & 0x3f), value & 0xff];
}

function writeId(id) {
  if (id <= 0xff) return [id];
  if (id <= 0xffff) return [(id >> 8) & 0xff, id & 0xff];
  if (id <= 0xffffff) return [(id >> 16) & 0xff, (id >> 8) & 0xff, id & 0xff];
  return [(id >> 24) & 0xff, (id >> 16) & 0xff, (id >> 8) & 0xff, id & 0xff];
}

function element(id, payload) {
  return [...writeId(id), ...writeVint(payload.length), ...payload];
}

function masterUnknown(id, children) {
  // Unknown size: 0x01 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF (8-byte VINT all-ones)
  const childBytes = children.flat();
  return [
    ...writeId(id),
    0x01,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    ...childBytes,
  ];
}

function master(id, children) {
  const childBytes = children.flat();
  return element(id, childBytes);
}

/**
 * Build a minimal valid WebM-like buffer that contains at least one
 * SimpleBlock with a synthetic Opus packet.
 *
 * Layout (simplified EBML):
 *   EBML Header (master)
 *   Segment (master, unknown size)
 *     Tracks (master)
 *       TrackEntry (master)
 *         Audio (master)
 *           Channels (uint, 1)
 *           SamplingFrequency (float64, 48000.0)
 *     Cluster (master, unknown size)
 *       SimpleBlock (track=1, timecode=0, flags=0, opus packet)
 */
function buildMinimalWebM() {
  const parts = [];

  // Channels = 1 (element 0x9F, uint8)
  const channels = element(0x9f, [1]);

  // SamplingFrequency = 48000.0 (element 0xB5, float64)
  const freqBuf = new ArrayBuffer(8);
  new DataView(freqBuf).setFloat64(0, 48000.0);
  const freqBytes = [...new Uint8Array(freqBuf)];
  const samplingFreq = element(0xb5, freqBytes);

  // Audio master (0xE1)
  const audio = master(0xe1, [channels, samplingFreq]);

  // TrackEntry (0xAE)
  const trackEntry = master(0xae, [audio]);

  // Tracks (0x1654AE6B)
  const tracks = master(0x1654ae6b, [trackEntry]);

  // Build a SimpleBlock (0xA3)
  // Track number = 1 (VINT: 0x81), timecode = 0 (int16 BE: 0x00 0x00), flags = 0x00
  // Followed by a synthetic Opus packet (TOC byte = 0xFC → config=31 CELT FB 20ms, code=0 → 1 frame)
  const opusPacket = [0xfc, 0x00, 0x01, 0x02, 0x03]; // 5-byte synthetic Opus packet
  const simpleBlockPayload = [0x81, 0x00, 0x00, 0x00, ...opusPacket]; // track=1, timecode=0, flags=0
  const simpleBlock = element(0xa3, simpleBlockPayload);

  // Cluster (0x1F43B675) with unknown size
  const cluster = masterUnknown(0x1f43b675, [simpleBlock]);

  // Segment (0x18538067) with unknown size
  const segment = masterUnknown(0x18538067, [tracks, cluster]);

  // EBML Header (0x1A45DFA3) — minimal
  const ebmlHeader = master(0x1a45dfa3, []);

  parts.push(...ebmlHeader, ...segment);

  return new Uint8Array(parts);
}

describe('remuxWebmToOgg', () => {
  it('returns the original Blob when input starts with OggS', async () => {
    const oggBytes = new Uint8Array([0x4f, 0x67, 0x67, 0x53, 0x00, 0x01, 0x02]);
    const oggBlob = blobFrom(oggBytes);

    const result = await remuxWebmToOgg(oggBlob);

    // Should be the exact same Blob reference (passthrough)
    expect(result).toBe(oggBlob);
  });

  it('throws an error when parseWebM yields no frames', async () => {
    // An empty Blob (no EBML data, no OggS magic) → parseWebM finds no frames
    const emptyBlob = blobFrom(new Uint8Array([0x00, 0x00, 0x00, 0x00]));

    await expect(remuxWebmToOgg(emptyBlob)).rejects.toThrow(
      'No Opus frames found in WebM input'
    );
  });

  it('remuxes a minimal WebM input into valid OGG output', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);

    expect(result).toBeInstanceOf(Blob);
    expect(result.type).toBe('audio/ogg');

    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);

    // Must start with OggS capture pattern
    expect(outBytes[0]).toBe(0x4f); // O
    expect(outBytes[1]).toBe(0x67); // g
    expect(outBytes[2]).toBe(0x67); // g
    expect(outBytes[3]).toBe(0x53); // S

    // Count OGG pages (each starts with "OggS")
    let pageCount = 0;
    for (let i = 0; i <= outBytes.length - 4; i += 1) {
      if (
        outBytes[i] === 0x4f &&
        outBytes[i + 1] === 0x67 &&
        outBytes[i + 2] === 0x67 &&
        outBytes[i + 3] === 0x53
      ) {
        pageCount += 1;
      }
    }

    // At least 3 pages: OpusHead (BOS) + OpusTags + audio page(s)
    expect(pageCount).toBeGreaterThanOrEqual(3);
  });

  it('has sequential page numbers in OGG output', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);
    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);
    const dv = new DataView(outBuf);

    // Collect page sequence numbers from OGG pages (offset 18 in each page header)
    const pageSeqs = [];
    for (let i = 0; i <= outBytes.length - 27; i += 1) {
      if (
        outBytes[i] === 0x4f &&
        outBytes[i + 1] === 0x67 &&
        outBytes[i + 2] === 0x67 &&
        outBytes[i + 3] === 0x53
      ) {
        pageSeqs.push(dv.getUint32(i + 18, true));
      }
    }

    // Pages should be 0, 1, 2, ...
    pageSeqs.forEach((seq, idx) => {
      expect(seq).toBe(idx);
    });
  });

  it('has the same serial number across all pages', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);
    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);
    const dv = new DataView(outBuf);

    const serials = [];
    for (let i = 0; i <= outBytes.length - 27; i += 1) {
      if (
        outBytes[i] === 0x4f &&
        outBytes[i + 1] === 0x67 &&
        outBytes[i + 2] === 0x67 &&
        outBytes[i + 3] === 0x53
      ) {
        serials.push(dv.getUint32(i + 14, true));
      }
    }

    // All pages share the same serial
    const unique = [...new Set(serials)];
    expect(unique).toHaveLength(1);
  });

  it('first page contains OpusHead', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);
    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);

    // First page is BOS (header_type byte at offset 5 has bit 0x02 set)
    expect(outBytes[5] & 0x02).toBe(0x02);

    // Find the segment data in first page and check for OpusHead magic
    const numSegments = outBytes[26];
    const dataStart = 27 + numSegments;
    const magic = new TextDecoder().decode(
      outBytes.slice(dataStart, dataStart + 8)
    );
    expect(magic).toBe('OpusHead');
  });

  it('second page contains OpusTags', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);
    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);

    // Find second OggS page
    const pageStarts = [];
    for (let i = 0; i <= outBytes.length - 4; i += 1) {
      if (
        outBytes[i] === 0x4f &&
        outBytes[i + 1] === 0x67 &&
        outBytes[i + 2] === 0x67 &&
        outBytes[i + 3] === 0x53
      ) {
        pageStarts.push(i);
      }
    }

    expect(pageStarts.length).toBeGreaterThanOrEqual(2);
    const page2Start = pageStarts[1];
    const numSegments = outBytes[page2Start + 26];
    const dataStart = page2Start + 27 + numSegments;
    const magic = new TextDecoder().decode(
      outBytes.slice(dataStart, dataStart + 8)
    );
    expect(magic).toBe('OpusTags');
  });

  it('last page has EOS flag set', async () => {
    const webmBytes = buildMinimalWebM();
    const webmBlob = blobFrom(webmBytes);

    const result = await remuxWebmToOgg(webmBlob);
    const outBuf = await readBlobAsArrayBuffer(result);
    const outBytes = new Uint8Array(outBuf);

    // Find the last OggS page
    let lastPageStart = -1;
    for (let i = 0; i <= outBytes.length - 4; i += 1) {
      if (
        outBytes[i] === 0x4f &&
        outBytes[i + 1] === 0x67 &&
        outBytes[i + 2] === 0x67 &&
        outBytes[i + 3] === 0x53
      ) {
        lastPageStart = i;
      }
    }

    expect(lastPageStart).toBeGreaterThan(0);
    // EOS flag = 0x04
    expect(outBytes[lastPageStart + 5] & 0x04).toBe(0x04);
  });

  it('logs warning for laced SimpleBlock', async () => {
    const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

    // Build a WebM with a laced SimpleBlock (flags byte with lacing bits set)
    const parts = [];

    const tracks = master(0x1654ae6b, [
      master(0xae, [master(0xe1, [element(0x9f, [1])])]),
    ]);

    // SimpleBlock with lacing bits set (flags = 0x06 → Xiph lacing)
    const opusPacket = [0xfc, 0x00, 0x01];
    const simpleBlockPayload = [0x81, 0x00, 0x00, 0x06, ...opusPacket];
    const simpleBlock = element(0xa3, simpleBlockPayload);
    const cluster = masterUnknown(0x1f43b675, [simpleBlock]);
    const segment = masterUnknown(0x18538067, [tracks, cluster]);
    const ebmlHeader = master(0x1a45dfa3, []);

    parts.push(...ebmlHeader, ...segment);

    const webmBlob = blobFrom(new Uint8Array(parts));
    // Should still produce output (not crash), but warn
    const result = await remuxWebmToOgg(webmBlob);
    expect(result).toBeInstanceOf(Blob);

    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('laced SimpleBlock detected')
    );

    consoleSpy.mockRestore();
  });
});
