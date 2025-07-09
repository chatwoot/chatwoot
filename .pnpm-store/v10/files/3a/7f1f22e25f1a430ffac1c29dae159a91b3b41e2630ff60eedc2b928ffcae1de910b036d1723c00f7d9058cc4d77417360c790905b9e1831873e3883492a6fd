export default function sha1(b) {
  var i,
    W = [],
    A, B, C, D,
    h = [ A = 0x67452301, B = 0xEFCDAB89, ~A, ~B, 0xC3D2E1F0 ],
    words = [],
    s = unescape(encodeURI(b)) + '\x80',
    j = s.length;

  // See "Length bits" in notes
  words[b = (--j / 4 + 2) | 15] = j * 8;

  for (; ~j;) { // j !== -1
    words[j >> 2] |= s.charCodeAt(j) << 8 * ~j--;
    // words[j >> 2] |= s.charCodeAt(j) << 24 - 8 * j--;
  }

  for (i = j = 0; i < b; i += 16) {
    A = h;

    for (; j < 80;
      A = [
        (
          A[4] +
          (
            W[j] =
              (j < 16)
                ? ~~words[i + j]
                : s * 2 | s < 0 // s << 1 | s >>> 31
          ) +
          1518500249 +
          [
            (B & C | ~B & D),
            s = (B ^ C ^ D) + 341275144,
            (B & C | B & D | C & D) + 882459459,
            s + 1535694389
          ][/* 0 | (j++ / 20)*/j++ / 5 >> 2] +
          ((s = A[0]) << 5 | s >>> 27)
        ),
        s,
        B << 30 | B >>> 2,
        C,
        D
      ]
    ) {
      s = W[j - 3] ^ W[j - 8] ^ W[j - 14] ^ W[j - 16];
      B = A[1];
      C = A[2];
      D = A[3];
    }

    // See "Integer safety" in notes
    for (j = 5; j;) h[--j] += A[j];

    // j === 0
  }

  for (s = ''; j < 40;) {
    // s += ((h[j >> 3] >> 4 * ~j++) & 15).toString(16);
    s += (h[j >> 3] >> (7 - j++) * 4 & 15).toString(16);
    // s += ((h[j >> 3] >> -4 * ++j) & 15).toString(16);
  }

  return s;
}
