# Font

The `src/fonts` directory contains the generated font used in the videojs-record plugin.

The font provides extra icons used in the plugin.

Continue reading if you want to customize or generate the font.

## Setup

To modify and update the generated fonts, checkout a copy of the video.js
[font](https://github.com/videojs/font) repository:

```console
cd /tmp
git clone https://github.com/videojs/font.git
cd font
```

Install the `grunt-cli` tool if you don't have it already (you might
need root user permissions here):

```console
npm install -g grunt-cli
```

Install the dependencies:

```console
npm install
```

## Build

Copy the videojs-record `icons.json` to the root of the `font`
repository using a different name, e.g. `videojs-record-icons.json`:

```console
cp -v /path/to/videojs-record/src/fonts/icons.json /path/to/font/videojs-record-icons.json
```

Build the fonts and styles:

```console
grunt --exclude-default --custom-json=videojs-record-icons.json
```

Open `index.html` in a browser to see the font and icons in action.

## Update

Copy the generated `_icons.scss` and various font files back to the `videojs-record`
repository:

```console
cp -v scss/_icons.scss /path/to/videojs-record/src/css/
cp -v fonts/videojs-record.* /path/to/videojs-record/src/fonts/
```

If you also want to copy them to the `dist` directory (optional as it's done
again during a build):

```console
cd /path/to/videojs-record/
npm run build
```

## References

Check the video.js font project [documentation](https://github.com/videojs/font/blob/master/README.md)
for more information.
