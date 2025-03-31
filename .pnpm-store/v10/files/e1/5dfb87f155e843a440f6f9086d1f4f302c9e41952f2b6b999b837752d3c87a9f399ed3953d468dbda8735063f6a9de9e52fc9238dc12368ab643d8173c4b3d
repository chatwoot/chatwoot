// See "precomputation" in notes
var i = 18,
  j,
  K = [],
  H = [];

// Construct list of primes < 320
// K[x] === 1 if x is composite, unset if prime
for (;i > 1; i--) {
  for (j = i; j < 320;) {
    K[j += i] = 1;
  }
}

// See "`a` reassignment" in notes
function a(num, root) {
  return (Math.pow(num, 1 / root) /* % 1 */) * 4294967296|0;
}

// i === 1
for (j = 0; j < 64;) {
  if (!K[++i]) {
    H[j] = a(i, 2);
    K[j++] = a(i, 3);
  }
}

function S(X, n) {
  return (X >>> n) | (X << (-n));
}

export default function sha256(b) {
  var
    h = H.slice(i = j = 0, 8),
    words = [],
    s = unescape(encodeURI(b)) + '\x80',
    W = s.length;

  // See "Length bits" in notes
  words[b = (--W / 4 + 2) | 15] = W * 8;

  for (; ~W;) { // W !== -1
    words[W >> 2] |= s.charCodeAt(W) << 8 * ~W--;
    // words[W >> 2] |= s.charCodeAt(W) << 24 - 8 * W--;
  }


  for (W = []; i < b; i += 16) {
    // See "`a` reassignment" in notes
    a = h.slice();

    for (; j < 64;
      a.unshift(
        s +
        (S(s = a[0], 2) ^ S(s, 13) ^ S(s, 22)) +
        ((s & a[1]) ^ (a[1] & a[2]) ^ (a[2] & s))
      )
    ) {
      a[3] += (
        s = 0 |
            (
              W[j] =
                (j < 16)
                  ? ~~words[j + i]
                  : (S(s = W[j - 2], 17) ^ S(s, 19) ^ (s >>> 10)) +
                    W[j - 7] +
                    (S(s = W[j - 15], 7) ^ S(s, 18) ^ (s >>> 3)) +
                    W[j - 16]

            ) +
            a.pop() +
            (S(s = a[4], 6) ^ S(s, 11) ^ S(s, 25)) +
            ((s & a[5]) ^ (~s & a[6])) +
            K[j++]
      );
    }

    // See "Integer safety" in notes
    for (j = 8; j;) h[--j] += a[j];

    // j === 0
  }

  for (s = ''; j < 64;) {
    // s += ((h[j >> 3] >> 4 * ~j++) & 15).toString(16);
    s += ((h[j >> 3] >> 4 * (7 - j++)) & 15).toString(16);
    // s += ((h[j >> 3] >> -4 * ++j) & 15).toString(16);
  }

  return s;
}
