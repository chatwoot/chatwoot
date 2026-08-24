// Generates Pawly platform icons (PNG/ICO/ICNS) for the Whisker desktop pet.
// Run with: node scripts/generate-icons.mjs
// Requires no external deps (uses built-in zlib).
import zlib from 'node:zlib';
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, '..', 'src-tauri', 'icons');

const TEAL = [0x1f, 0xe0, 0xb5];
const BLUE = [0x1b, 0xa5, 0xff];

function clamp(v) { return v < 0 ? 0 : v > 255 ? 255 : v; }

// Draw Pawly: teal disc with a white paw print. Returns RGBA buffer (N*N*4).
function renderPawly(N) {
  const buf = new Uint8Array(N * N * 4);
  const cx = (N - 1) / 2;
  const cy = (N - 1) / 2;
  const r = N * 0.46;

  // paw geometry (relative to N)
  const pad = { x: 0, y: 0.10, rx: 0.17, ry: 0.145 };
  const toes = [
    { x: -0.19, y: -0.12, rad: 0.085 },
    { x: -0.065, y: -0.19, rad: 0.085 },
    { x: 0.065, y: -0.19, rad: 0.085 },
    { x: 0.19, y: -0.12, rad: 0.085 },
  ];

  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      const i = (y * N + x) * 4;
      const dx = x - cx;
      const dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy) / r;
      // anti-aliased disc edge
      let alpha = 1 - smoothstep(0.97, 1.03, dist);
      if (alpha <= 0) { buf[i + 3] = 0; continue; }

      // vertical gradient across the disc
      const t = clamp((dy / r + 1) / 2);
      const cr = Math.round(TEAL[0] + (BLUE[0] - TEAL[0]) * t);
      const cg = Math.round(TEAL[1] + (BLUE[1] - TEAL[1]) * t);
      const cb = Math.round(TEAL[2] + (BLUE[2] - TEAL[2]) * t);

      let R = cr, G = cg, B = cb, A = alpha;

      // white paw print (additive over disc)
      const px = dx / N;
      const py = dy / N;
      const inPad = ellipse(px, py, pad.x, pad.y, pad.rx, pad.ry);
      let inToe = 0;
      for (const toe of toes) {
        const d = Math.sqrt((px - toe.x) ** 2 + (py - toe.y) ** 2) / toe.rad;
        inToe = Math.max(inToe, 1 - smoothstep(0.9, 1.0, d));
      }
      const paw = Math.max(inPad, inToe);
      if (paw > 0) {
        // blend white with slight AA
        const w = paw * alpha;
        R = Math.round(R * (1 - w) + 255 * w);
        G = Math.round(G * (1 - w) + 255 * w);
        B = Math.round(B * (1 - w) + 255 * w);
      }
      buf[i] = R; buf[i + 1] = G; buf[i + 2] = B; buf[i + 3] = Math.round(A * 255);
    }
  }
  return buf;
}

function ellipse(px, py, ex, ey, rx, ry) {
  const v = ((px - ex) ** 2) / (rx * rx) + ((py - ey) ** 2) / (ry * ry);
  return 1 - smoothstep(0.9, 1.05, v);
}

function smoothstep(edge0, edge1, x) {
  const t = clamp((x - edge0) / (edge1 - edge0));
  return t * t * (3 - 2 * t);
}

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return (~c) >>> 0;
}

function pngChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function encodePNG(N, rgba) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(N, 0);
  ihdr.writeUInt32BE(N, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  // raw scanlines with filter byte 0
  const raw = Buffer.alloc(N * (N * 4 + 1));
  for (let y = 0; y < N; y++) {
    raw[y * (N * 4 + 1)] = 0;
    rgba.copy(raw, y * (N * 4 + 1) + 1, y * N * 4, (y + 1) * N * 4);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([
    sig,
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', idat),
    pngChunk('IEND', Buffer.alloc(0)),
  ]);
}

function encodeICO(sizes) {
  // simple ICO wrapping PNGs
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2); // type icon
  header.writeUInt16LE(sizes.length, 4);
  const entries = Buffer.alloc(sizes.length * 16);
  const imageData = [];
  let offset = 6 + sizes.length * 16;
  sizes.forEach((png, idx) => {
    entries.writeUInt8(png.width >= 256 ? 0 : png.width, idx * 16);
    entries.writeUInt8(png.height >= 256 ? 0 : png.height, idx * 16 + 1);
    entries.writeUInt8(0, idx * 16 + 2);
    entries.writeUInt8(0, idx * 16 + 3);
    entries.writeUInt16LE(1, idx * 16 + 4);
    entries.writeUInt16LE(32, idx * 16 + 6);
    entries.writeUInt32LE(png.buf.length, idx * 16 + 8);
    entries.writeUInt32LE(offset, idx * 16 + 12);
    imageData.push(png.buf);
    offset += png.buf.length;
  });
  return Buffer.concat([header, entries, ...imageData]);
}

function encodeICNS(images) {
  // ICNS with embedded PNGs (type ic07=128, ic08=256, ic09=512, ic10=1024, ic11=32, ic12=64, ic13=256, ic14=512)
  const map = { 32: 'ic11', 128: 'ic07', 256: 'ic08', 512: 'ic09' };
  const parts = [];
  for (const img of images) {
    const type = map[img.width];
    if (!type) continue;
    const data = img.buf;
    const chunk = Buffer.alloc(8 + data.length);
    chunk.write(type, 0, 'ascii');
    chunk.writeUInt32BE(data.length + 4, 4);
    data.copy(chunk, 8);
    parts.push(chunk);
  }
  const body = Buffer.concat(parts);
  const out = Buffer.alloc(8 + body.length);
  out.write('icns', 0, 'ascii');
  out.writeUInt32BE(body.length + 8, 4);
  body.copy(out, 8);
  return out;
}

mkdirSync(OUT, { recursive: true });

const specs = [
  { name: '32x32.png', size: 32 },
  { name: '128x128.png', size: 128 },
  { name: '128x128@2x.png', size: 256 },
  { name: 'icon.png', size: 512 },
];

const pngs = specs.map((s) => {
  const buf = renderPawly(s.size);
  const png = encodePNG(s.size, Buffer.from(buf));
  writeFileSync(join(OUT, s.name), png);
  return { width: s.size, buf: png };
});

// ico uses 16,32,48,256
const icoSizes = [16, 32, 48, 256].map((n) => ({ width: n, buf: encodePNG(n, Buffer.from(renderPawly(n))) }));
writeFileSync(join(OUT, 'icon.ico'), encodeICO(icoSizes));

// icns uses 32,128,256,512
const icnsSizes = [32, 128, 256, 512].map((n) => ({ width: n, buf: encodePNG(n, Buffer.from(renderPawly(n))) }));
writeFileSync(join(OUT, 'icon.icns'), encodeICNS(icnsSizes));

console.log('Pawly icons generated in', OUT);
