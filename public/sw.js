/* eslint-disable */
/** *
 *
 * The rest of the code is auto-generated. Please don't update this file
 * directly; instead, make changes to your Workbox build configuration
 * and re-run your build process.
 * See https://goo.gl/2aRDsh
 */

 importScripts("https://storage.googleapis.com/workbox-cdn/releases/4.3.1/workbox-sw.js");

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

/**
 * The workboxSW.precacheAndRoute() method efficiently caches and responds to
 * requests for URLs in the manifest.
 * See https://goo.gl/S9QRab
 */
self.__precacheManifest = [
  {
    "url": "android-icon-144x144.png",
    "revision": "d9e3ad004635d6d3154da20ef6e53077"
  },
  {
    "url": "android-icon-192x192.png",
    "revision": "8f2f76058ff81bb03e390ed941f68a70"
  },
  {
    "url": "android-icon-36x36.png",
    "revision": "70b2fa97615a1ccf8fa373674928d0e3"
  },
  {
    "url": "android-icon-48x48.png",
    "revision": "c0e8a16e2ea4430deddac82979f97c60"
  },
  {
    "url": "android-icon-72x72.png",
    "revision": "98f4881cce0daf4b89f0b30825b16d80"
  },
  {
    "url": "android-icon-96x96.png",
    "revision": "02cf787c7a88eb898976d79ad0b4e041"
  },
  {
    "url": "apple-icon-114x114.png",
    "revision": "544c150aa39d3ecfd6071e3c54d1503e"
  },
  {
    "url": "apple-icon-120x120.png",
    "revision": "3b10208d8f4b09c5c3631eb5e4e67d9a"
  },
  {
    "url": "apple-icon-144x144.png",
    "revision": "d9e3ad004635d6d3154da20ef6e53077"
  },
  {
    "url": "apple-icon-152x152.png",
    "revision": "a866770945a41e5bcf29706f37e5beba"
  },
  {
    "url": "apple-icon-180x180.png",
    "revision": "327e9272f10374d2859d2a26c86698ec"
  },
  {
    "url": "apple-icon-57x57.png",
    "revision": "ee6e09647e6a26e29655ed4091a6d577"
  },
  {
    "url": "apple-icon-60x60.png",
    "revision": "136acdd5567a57f0b30c4704c93ce412"
  },
  {
    "url": "apple-icon-72x72.png",
    "revision": "98f4881cce0daf4b89f0b30825b16d80"
  },
  {
    "url": "apple-icon-76x76.png",
    "revision": "5de2acd8f66a8fa583830286231abe88"
  },
  {
    "url": "apple-icon-precomposed.png",
    "revision": "03175edf677b78aae0c7ce1c90996bcc"
  },
  {
    "url": "apple-icon.png",
    "revision": "03175edf677b78aae0c7ce1c90996bcc"
  },
  {
    "url": "apple-touch-icon-precomposed.png",
    "revision": "d41d8cd98f00b204e9800998ecf8427e"
  },
  {
    "url": "apple-touch-icon.png",
    "revision": "d41d8cd98f00b204e9800998ecf8427e"
  },
  {
    "url": "favicon-16x16.png",
    "revision": "df49c81fbfd18e43ea9199153f1d5e1f"
  },
  {
    "url": "favicon-32x32.png",
    "revision": "e781cbd8ca95543e247fa913eef30f9c"
  },
  {
    "url": "favicon-512x512.png",
    "revision": "48e48806ef9cbe9edcbe81a08713dc7f"
  },
  {
    "url": "favicon-96x96.png",
    "revision": "02cf787c7a88eb898976d79ad0b4e041"
  },
  {
    "url": "favicon.ico",
    "revision": "788f4b1590d83444281e0c96792fd42b"
  },
  {
    "url": "ms-icon-144x144.png",
    "revision": "d9e3ad004635d6d3154da20ef6e53077"
  },
  {
    "url": "ms-icon-150x150.png",
    "revision": "0770f6909fd7676a02922cd34d23ff15"
  },
  {
    "url": "ms-icon-310x310.png",
    "revision": "492181f5f2a4c199936f7f03c70e4914"
  },
  {
    "url": "ms-icon-70x70.png",
    "revision": "c1b4c1be97c6768c0e5547c2b07bf2a2"
  }
].concat(self.__precacheManifest || []);
workbox.precaching.precacheAndRoute(self.__precacheManifest, {});
