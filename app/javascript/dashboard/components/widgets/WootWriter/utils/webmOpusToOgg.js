/* eslint-disable no-bitwise */
/**
 * WebM/Opus → OGG/Opus remuxer
 *
 * Chrome's MediaRecorder produces WebM containers even when
 * `audio/ogg;codecs=opus` is requested. WhatsApp Cloud API requires
 * proper OGG/Opus files for voice messages.
 *
 * This module extracts raw Opus packets from the WebM (EBML) container
 * and repackages them into a valid OGG bitstream. The audio data itself
 * is never re-encoded — only the container format changes.
 *
 * References:
 *   EBML (container for WebM):   RFC 8794 — https://www.rfc-editor.org/rfc/rfc8794
 *   Matroska/WebM elements:      https://www.matroska.org/technical/elements.html
 *   OGG bitstream framing:       RFC 3533 — https://www.rfc-editor.org/rfc/rfc3533
 *   Opus codec:                  RFC 6716 — https://www.rfc-editor.org/rfc/rfc6716
 *   Opus in OGG (OpusHead/Tags): RFC 7845 — https://www.rfc-editor.org/rfc/rfc7845
 */

// ======================== EBML / WebM parser ========================

const EBML_IDS = {
  Segment: 0x18538067,
  SegmentInfo: 0x1549a966,
  Tracks: 0x1654ae6b,
  TrackEntry: 0xae,
  CodecPrivate: 0x63a2,
  Audio: 0xe1,
  SamplingFrequency: 0xb5,
  Channels: 0x9f,
  Cluster: 0x1f43b675,
  Timecode: 0xe7,
  SimpleBlock: 0xa3,
  BlockGroup: 0xa0,
  Block: 0xa1,
};

const MASTER_ELEMENTS = new Set([
  0x1a45dfa3, // EBML header
  EBML_IDS.Segment,
  EBML_IDS.SegmentInfo,
  EBML_IDS.Tracks,
  EBML_IDS.TrackEntry,
  EBML_IDS.Audio,
  EBML_IDS.Cluster,
  EBML_IDS.BlockGroup,
]);

/** Read an EBML variable-length integer (data size). */
function readVint(data, pos) {
  if (pos >= data.length) return null;
  const first = data[pos];
  if (first === 0) return null;

  let len = 1;
  let mask = 0x80;
  while (len <= 8 && !(first & mask)) {
    len += 1;
    mask >>= 1;
  }
  if (len > 8 || pos + len > data.length) return null;

  let value = first & (mask - 1);
  for (let i = 1; i < len; i += 1) {
    value = value * 256 + data[pos + i];
  }
  return { value, length: len };
}

/** Read an EBML element ID (leading marker bits are kept). */
function readElementId(data, pos) {
  if (pos >= data.length) return null;
  const first = data[pos];
  if (first === 0) return null;

  let len = 1;
  let mask = 0x80;
  while (len <= 4 && !(first & mask)) {
    len += 1;
    mask >>= 1;
  }
  if (len > 4 || pos + len > data.length) return null;

  let id = first;
  for (let i = 1; i < len; i += 1) {
    id = id * 256 + data[pos + i];
  }
  return { id, length: len };
}

function readUintBE(data, offset, length) {
  let v = 0;
  for (let i = 0; i < length; i += 1) v = v * 256 + data[offset + i];
  return v;
}

function readFloatBE(data, offset, length) {
  if (length !== 4 && length !== 8) return NaN;
  const buf = new ArrayBuffer(length);
  const u8 = new Uint8Array(buf);
  for (let i = 0; i < length; i += 1) u8[i] = data[offset + i];
  const view = new DataView(buf);
  return length === 4 ? view.getFloat32(0) : view.getFloat64(0);
}

/** Extract the raw Opus frame from a SimpleBlock / Block element. */
function extractFrameFromBlock(data, offset, end) {
  const trackVint = readVint(data, offset);
  if (!trackVint) return null;
  let pos = offset + trackVint.length;

  // int16 relative timecode (big-endian, signed) – skip
  pos += 2;
  // Flags byte – skip. Lacing (Xiph/EBML/fixed-size) is NOT supported;
  // this assumes single-frame blocks as produced by MediaRecorder.
  const flags = data[pos];
  const lacingBits = (flags >> 1) & 0x03;
  if (lacingBits !== 0) {
    // eslint-disable-next-line no-console
    console.warn(
      'webmOpusToOgg: laced SimpleBlock detected (unsupported), frame may be invalid'
    );
  }
  pos += 1;

  if (pos >= end) return null;
  return data.slice(pos, end);
}

/**
 * Walk the EBML tree and collect metadata + Opus frames.
 * We only descend into master elements and only extract the fields we need.
 */
function parseWebM(buffer) {
  const data = new Uint8Array(buffer);
  const result = {
    channels: 1,
    sampleRate: 48000,
    codecPrivate: null,
    frames: [],
  };

  function walk(start, end) {
    let pos = start;
    while (pos < end) {
      const idRes = readElementId(data, pos);
      if (!idRes) break;
      pos += idRes.length;

      const sizeRes = readVint(data, pos);
      if (!sizeRes) break;
      pos += sizeRes.length;

      // Handle "unknown size" (all-ones VINT) by treating it as the rest of the parent
      // Use Math.pow instead of bit-shift to avoid 32-bit overflow for 5+ byte VINTs
      const maxVint = 2 ** (7 * sizeRes.length) - 1;
      const elEnd =
        sizeRes.value === maxVint ? end : Math.min(pos + sizeRes.value, end);

      if (MASTER_ELEMENTS.has(idRes.id)) {
        walk(pos, elEnd);
      } else {
        switch (idRes.id) {
          case EBML_IDS.Channels:
            result.channels = readUintBE(data, pos, sizeRes.value);
            break;
          case EBML_IDS.SamplingFrequency:
            result.sampleRate = readFloatBE(data, pos, sizeRes.value);
            break;
          case EBML_IDS.CodecPrivate:
            result.codecPrivate = data.slice(pos, elEnd);
            break;
          case EBML_IDS.SimpleBlock:
          case EBML_IDS.Block: {
            const frame = extractFrameFromBlock(data, pos, elEnd);
            if (frame && frame.length > 0) result.frames.push(frame);
            break;
          }
          default:
            break;
        }
      }
      pos = elEnd;
    }
  }

  walk(0, data.length);
  return result;
}

// ======================== OGG writer ========================

/** OGG CRC-32 table (polynomial 0x04C11DB7). */
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let i = 0; i < 256; i += 1) {
    let c = i << 24;
    for (let j = 0; j < 8; j += 1) {
      c = ((c << 1) ^ (c & 0x80000000 ? 0x04c11db7 : 0)) >>> 0;
    }
    t[i] = c;
  }
  return t;
})();

function oggCrc32(bytes) {
  let crc = 0;
  for (let i = 0; i < bytes.length; i += 1) {
    crc = (CRC_TABLE[((crc >>> 24) ^ bytes[i]) & 0xff] ^ (crc << 8)) >>> 0;
  }
  return crc;
}

/**
 * Build one OGG page.
 *
 * @param {number}       headerType      0x02 = BOS, 0x04 = EOS, 0x00 = normal
 * @param {number}       granulePosition 48 kHz sample count
 * @param {number}       serialNumber    logical stream id
 * @param {number}       pageSeq         page sequence counter
 * @param {Uint8Array[]} packets         one or more complete Opus packets
 */
function createOggPage(
  headerType,
  granulePosition,
  serialNumber,
  pageSeq,
  packets
) {
  // Build the lacing / segment table
  const segTable = [];
  let dataLen = 0;
  packets.forEach(pkt => {
    let rem = pkt.length;
    while (rem >= 255) {
      segTable.push(255);
      rem -= 255;
    }
    segTable.push(rem); // final segment (0 when pkt.length is a multiple of 255)
    dataLen += pkt.length;
  });

  const hdrLen = 27 + segTable.length;
  const page = new Uint8Array(hdrLen + dataLen);
  const dv = new DataView(page.buffer);

  // Capture pattern
  page.set([0x4f, 0x67, 0x67, 0x53]); // "OggS"
  page[4] = 0; // version
  page[5] = headerType;

  // Granule position (int64 LE)
  dv.setUint32(6, granulePosition & 0xffffffff, true);
  dv.setUint32(
    10,
    Math.floor(granulePosition / 0x100000000) & 0xffffffff,
    true
  );

  dv.setUint32(14, serialNumber, true); // serial
  dv.setUint32(18, pageSeq, true); // page sequence
  dv.setUint32(22, 0, true); // CRC placeholder

  page[26] = segTable.length;
  for (let i = 0; i < segTable.length; i += 1) page[27 + i] = segTable[i];

  let off = hdrLen;
  packets.forEach(pkt => {
    page.set(pkt, off);
    off += pkt.length;
  });

  // Fill in the CRC
  dv.setUint32(22, oggCrc32(page), true);
  return page;
}

// ======================== Opus helpers ========================

/** Lookup table: frame duration in ms for each Opus TOC config index (0-31). */
const OPUS_FRAME_MS = [
  10,
  20,
  40,
  60, // 0-3   SILK NB
  10,
  20,
  40,
  60, // 4-7   SILK MB
  10,
  20,
  40,
  60, // 8-11  SILK WB
  10,
  20, // 12-13 Hybrid SWB
  10,
  20, // 14-15 Hybrid FB
  2.5,
  5,
  10,
  20, // 16-19 CELT NB
  2.5,
  5,
  10,
  20, // 20-23 CELT WB
  2.5,
  5,
  10,
  20, // 24-27 CELT SWB
  2.5,
  5,
  10,
  20, // 28-31 CELT FB
];

/** Return the total number of 48 kHz PCM samples represented by an Opus packet. */
function opusPacketSamples(pkt) {
  if (!pkt || pkt.length === 0) return 960; // default 20 ms
  const toc = pkt[0];
  const config = (toc >> 3) & 0x1f;
  const code = toc & 0x03;

  const samplesPerFrame = ((OPUS_FRAME_MS[config] || 20) * 48000) / 1000;
  let frameCount;
  if (code <= 1) frameCount = code + 1;
  else if (code === 2) frameCount = 2;
  else frameCount = pkt.length >= 2 ? pkt[1] & 0x3f : 1;

  return samplesPerFrame * frameCount;
}

function buildOpusHead(channels, sampleRate, preSkip) {
  const buf = new Uint8Array(19);
  const dv = new DataView(buf.buffer);
  buf.set(new TextEncoder().encode('OpusHead'));
  buf[8] = 1; // version
  buf[9] = channels;
  dv.setUint16(10, preSkip, true);
  dv.setUint32(12, sampleRate, true);
  dv.setInt16(16, 0, true); // output gain
  buf[18] = 0; // channel mapping family
  return buf;
}

function buildOpusTags() {
  const vendor = new TextEncoder().encode('chatwoot');
  const buf = new Uint8Array(8 + 4 + vendor.length + 4);
  const dv = new DataView(buf.buffer);
  buf.set(new TextEncoder().encode('OpusTags'));
  dv.setUint32(8, vendor.length, true);
  buf.set(vendor, 12);
  dv.setUint32(12 + vendor.length, 0, true); // 0 user comments
  return buf;
}

// ======================== Public API ========================

const MAX_FRAMES_PER_PAGE = 50; // ~1 s at 20 ms/frame
const MAX_SEGMENTS_PER_PAGE = 255;

/**
 * Remux a WebM/Opus blob into an OGG/Opus blob.
 * If the input is already OGG (starts with "OggS"), it is returned as-is.
 *
 * @param {Blob} webmBlob
 * @returns {Promise<Blob>} OGG/Opus blob
 */
export async function remuxWebmToOgg(webmBlob) {
  const buffer = await webmBlob.arrayBuffer();
  const bytes = new Uint8Array(buffer);

  // Already OGG? Return unchanged.
  if (
    bytes.length >= 4 &&
    bytes[0] === 0x4f &&
    bytes[1] === 0x67 &&
    bytes[2] === 0x67 &&
    bytes[3] === 0x53
  ) {
    return webmBlob;
  }

  const { channels, sampleRate, codecPrivate, frames } = parseWebM(buffer);
  if (frames.length === 0) {
    throw new Error('No Opus frames found in WebM input');
  }

  // Extract pre-skip from the WebM CodecPrivate (which IS the OpusHead)
  let preSkip = 312;
  if (codecPrivate && codecPrivate.length >= 12) {
    const magic = new TextDecoder().decode(codecPrivate.slice(0, 8));
    if (magic === 'OpusHead') {
      preSkip = new DataView(
        codecPrivate.buffer,
        codecPrivate.byteOffset,
        codecPrivate.length
      ).getUint16(10, true);
    }
  }

  const serial = (Math.random() * 0x100000000) >>> 0;
  let pageSeq = 0;
  const pages = [];

  // Page 0 – OpusHead (BOS)
  pages.push(
    createOggPage(0x02, 0, serial, pageSeq, [
      buildOpusHead(channels, sampleRate, preSkip),
    ])
  );
  pageSeq += 1;

  // Page 1 – OpusTags
  pages.push(createOggPage(0x00, 0, serial, pageSeq, [buildOpusTags()]));
  pageSeq += 1;

  // Audio pages
  let granule = 0;
  let idx = 0;

  while (idx < frames.length) {
    const packets = [];
    let segs = 0;

    while (idx < frames.length && packets.length < MAX_FRAMES_PER_PAGE) {
      const pkt = frames[idx];
      const pktSegs = Math.ceil(pkt.length / 255) || 1;
      if (segs + pktSegs > MAX_SEGMENTS_PER_PAGE && packets.length > 0) break;

      packets.push(pkt);
      segs += pktSegs;
      granule += opusPacketSamples(pkt);
      idx += 1;
    }

    const isLast = idx >= frames.length;
    pages.push(
      createOggPage(isLast ? 0x04 : 0x00, granule, serial, pageSeq, packets)
    );
    pageSeq += 1;
  }

  // Concatenate pages into a single buffer
  const total = pages.reduce((s, p) => s + p.length, 0);
  const out = new Uint8Array(total);
  let off = 0;
  pages.forEach(p => {
    out.set(p, off);
    off += p.length;
  });

  return new Blob([out], { type: 'audio/ogg' });
}
