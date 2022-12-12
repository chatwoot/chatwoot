# Convert Colors [<img src="https://cdn.worldvectorlogo.com/logos/nodejs-icon.svg" alt="Convert Colors" width="90" height="90" align="right">][Convert Colors]

[![NPM Version][npm-img]][npm-url]
[![Linux Build Status][cli-img]][cli-url]
[![Windows Build Status][win-img]][win-url]

[Convert Colors] converts colors between RGB, HSL, HWB, Lab, LCH, HSV, and XYZ.

```js
import convert from '@csstools/convert-colors';

convert.rgb2hsl(100, 100, 100); // [ 0, 0, 100 ]
convert.rgb2hwb(100, 100, 100); // [ 0, 100, 0 ]

convert.hsl2rgb(0, 0, 100); // [ 0, 100, 0 ]
convert.hsl2hwb(0, 0, 100); // [ 0, 100, 0 ]

convert.hwb2rgb(0, 100, 0); // [ 0, 0, 100 ]
convert.hwb2hsl(0, 100, 0); // [ 0, 0, 100 ]

convert.rgb2hue(0, 0, 100); // 240
```

## Usage

Add [Convert Colors] to your build tool:

```bash
npm install @csstools/convert-colors --save-dev
```

## Features

Conversions work by taking arguments that represents a color in one color space
and returning an array of that same color in another color space.

- rgb2hsl(r, g, b)
- rgb2hwb(r, g, b)
- rgb2lab(r, g, b)
- rgb2lch(r, g, b)
- rgb2hsv(r, g, b)
- rgb2xyz(r, g, b)
- hsl2rgb(h, s, l)
- hsl2hwb(h, s, l)
- hsl2lab(h, s, l)
- hsl2lch(h, s, l)
- hsl2hsv(h, s, l)
- hsl2xyz(h, s, l)
- hwb2rgb(h, w, b)
- hwb2hsl(h, w, b)
- hwb2lab(h, w, b)
- hwb2lch(h, w, b)
- hwb2hsv(h, w, b)
- hwb2xyz(h, w, b)
- lab2rgb(l, a, b)
- lab2hsl(l, a, b)
- lab2hwb(l, a, b)
- lab2lch(l, a, b)
- lab2hsv(l, a, b)
- lab2xyz(l, a, b)
- lch2rgb(l, c, h)
- lch2hsl(l, c, h)
- lch2hwb(l, c, h)
- lch2lab(l, c, h)
- lch2hsv(l, c, h)
- lch2xyz(l, c, h)
- hsv2rgb(h, s, v)
- hsv2hsl(h, s, v)
- hsv2hwb(h, s, v)
- hsv2lab(h, s, v)
- hsv2lch(h, s, v)
- hsv2xyz(h, s, v)
- xyz2rgb(x, y, z)
- xyz2hsl(x, y, z)
- xyz2hwb(x, y, z)
- xyz2lab(x, y, z)
- xyz2lch(x, y, z)
- xyz2hsv(x, y, z)

[npm-url]: https://www.npmjs.com/package/@csstools/convert-colors
[npm-img]: https://img.shields.io/npm/v/@csstools/convert-colors.svg
[cli-url]: https://travis-ci.org/jonathantneal/convert-colors
[cli-img]: https://img.shields.io/travis/jonathantneal/convert-colors.svg
[win-url]: https://ci.appveyor.com/project/jonathantneal/convert-colors
[win-img]: https://img.shields.io/appveyor/ci/jonathantneal/convert-colors.svg

[Convert Colors]: https://github.com/jonathantneal/convert-colors
