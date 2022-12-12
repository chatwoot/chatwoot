# chartjs-color-string

[![npm](https://img.shields.io/npm/v/chartjs-color-string.svg?style=flat-square&maxAge=600)](https://npmjs.com/package/chartjs-color-string) [![Travis](https://img.shields.io/travis/chartjs/chartjs-color-string.svg?style=flat-square&maxAge=600)](https://travis-ci.org/chartjs/chartjs-color-string)

> library for parsing and generating CSS color strings.

## Install

With [npm](http://npmjs.org/):

```console
$ npm install color-string
```

## Usage

### Parsing

```js
colorString.getRgb("blue")                       // [0, 0, 255]
colorString.getRgb("#FFF")                       // [255, 255, 255]
colorString.getRgba("#FFFA")                     //[255, 255, 255, 0.67]}
colorString.getRgba("#FFFFFFAA")                 // [255, 255, 255, 0.67]}

colorString.getRgba("rgba(200, 60, 60, 0.3)")    // [200, 60, 60, 0.3]
colorString.getRgba("rgb(200, 200, 200)")        // [200, 200, 200, 1]

colorString.getHsl("hsl(360, 100%, 50%)")        // [360, 100, 50]
colorString.getHsla("hsla(360, 60%, 50%, 0.4)")  // [360, 60, 50, 0.4]

colorString.getAlpha("rgba(200, 0, 12, 0.6)")    // 0.6
```

### Generation

```js
colorString.hexString([255, 255, 255])   // "#FFFFFF"
colorString.hexString([0, 0, 255, 0.4])    // "#0000FF66"
colorString.hexString([0, 0, 255], 0.4)    // "#0000FF66"
colorString.rgbString([255, 255, 255])   // "rgb(255, 255, 255)"
colorString.rgbString([0, 0, 255, 0.4])  // "rgba(0, 0, 255, 0.4)"
colorString.rgbString([0, 0, 255], 0.4)  // "rgba(0, 0, 255, 0.4)"
colorString.percentString([0, 0, 255])   // "rgb(0%, 0%, 100%)"
colorString.keyword([255, 255, 0])       // "yellow"
colorString.hslString([360, 100, 100])   // "hsl(360, 100%, 100%)"
```
