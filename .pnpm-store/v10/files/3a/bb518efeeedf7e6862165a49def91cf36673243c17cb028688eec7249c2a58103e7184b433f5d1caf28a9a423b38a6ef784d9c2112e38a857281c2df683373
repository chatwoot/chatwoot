{
  "name": "qrcode",
  "description": "QRCode / 2d Barcode api with both server side and client side support using canvas",
  "version": "1.5.4",
  "author": "Ryan Day <soldair@gmail.com>",
  "contributors": [
    "Vincenzo Greco <greco.vincenzo@gmail.com>",
    "Linus Unnebäck <linus@folkdatorn.se>"
  ],
  "keywords": [
    "qr",
    "code",
    "canvas",
    "qrcode"
  ],
  "main": "./lib/index.js",
  "browser": {
    "./lib/index.js": "./lib/browser.js",
    "fs": false
  },
  "files": [
    "bin",
    "build",
    "lib",
    "helper"
  ],
  "homepage": "http://github.com/soldair/node-qrcode",
  "license": "MIT",
  "scripts": {
    "lint": "standard",
    "pretest": "npm run lint",
    "test": "node --throw-deprecation test.js",
    "build": "rollup -c",
    "prepublish": "npm run build",
    "browser": "node examples/clientsideserver.js"
  },
  "bin": {
    "qrcode": "./bin/qrcode"
  },
  "dependencies": {
    "dijkstrajs": "^1.0.1",
    "pngjs": "^5.0.0",
    "yargs": "^15.3.1"
  },
  "devDependencies": {
    "@babel/core": "^7.9.0",
    "@babel/preset-env": "^7.9.5",
    "@rollup/plugin-commonjs": "^11.1.0",
    "@rollup/plugin-node-resolve": "^7.1.3",
    "browserify": "^16.5.1",
    "canvas": "^2.8.0",
    "canvasutil": "0.0.4",
    "colors": "^1.4.0",
    "express": "^4.17.1",
    "htmlparser2": "^4.1.0",
    "rollup": "^2.6.1",
    "rollup-plugin-babel": "^4.4.0",
    "rollup-plugin-terser": "^5.3.0",
    "sinon": "^9.0.2",
    "standard": "^16.0.4",
    "tap": "^16.2.0"
  },
  "repository": {
    "type": "git",
    "url": "git://github.com/soldair/node-qrcode.git"
  },
  "engines": {
    "node": ">=10.13.0"
  },
  "standard": {
    "ignore": [
      "build/",
      "examples/vendors/",
      "lib/core/regex.js"
    ]
  }
}
