# aes-decrypter

[![Build Status](https://travis-ci.org/videojs/aes-decrypter.svg?branch=master)](https://travis-ci.org/videojs/aes-decrypter)
[![Greenkeeper badge](https://badges.greenkeeper.io/videojs/aes-decrypter.svg)](https://greenkeeper.io/)
[![Slack Status](http://slack.videojs.com/badge.svg)](http://slack.videojs.com)

[![NPM](https://nodei.co/npm/aes-decrypter.png?downloads=true&downloadRank=true)](https://nodei.co/npm/aes-decrypter/)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
## Installation

```sh
npm install --save aes-decrypter
```

Also available to install globally:

```sh
npm install --global aes-decrypter
```

The npm installation is preferred, but Bower works, too.

```sh
bower install  --save aes-decrypter
```

## Usage

To include decrypter on your website or npm application, use any of the following methods.
```js
var Decrypter = require('aes-decrypter').Decrypter;
var fs = require('fs');
var keyContent = fs.readFileSync('something.key');
var encryptedBytes = fs.readFileSync('somithing.txt');

// keyContent is a string of the aes-keys content
var keyContent = fs.readFileSync(keyFile);

var view = new DataView(keyContent.buffer);
var key.bytes = new Uint32Array([
  view.getUint32(0),
  view.getUint32(4),
  view.getUint32(8),
  view.getUint32(12)
]);

key.iv = new Uint32Array([
  0, 0, 0, 0
]);

var d = new Decrypter(
  encryptedBytes,
  key.bytes,
  key.iv,
  function(err, decryptedBytes) {
    // err always null
});
```

## [License](LICENSE)

Apache-2.0. Copyright (c) Brightcove, Inc.

