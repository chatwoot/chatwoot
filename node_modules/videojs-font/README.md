# Video.js Icon Font

This project contains all of the tooling necessary to generate a new icon font for Video.js. The icons themselves are from
Google's [Material Design Icons](https://github.com/google/material-design-icons).

You can see an overview of the icons used in the default Video.js font here: https://videojs.github.io/font/

## Usage

```sh
$ npm install grunt-cli # only if you don't already have grunt installed
$ npm install
$ grunt
```

### Custom icons

You can add custom icons by calling grunt with the `--custom-json` option. It takes a comma delimited list of paths to JSON files of the same format as below and merges it with the default icons file.

Example:
```sh
$ grunt --custom-json=./lib/custom.json,./lib/custom2.json
```

## Making changes to the font

To make changes to the default Video.js font, simply edit the `icons.json` file. You can add or remove icons, either by just selecting new
SVGs from the [Material Design set](https://www.google.com/design/icons/), or pulling in new SVGs altogether.

```json
{
  "font-name": "VideoJS",
  "root-dir": "./node_modules/material-design-icons/",
  "icons": [
    {
      "name": "play",
      "svg": "av/svg/production/ic_play_arrow_48px.svg"
    },
    {
      "name": "pause",
      "svg": "av/svg/production/ic_pause_48px.svg"
    },
    {
      "name": "cool-custom-icon",
      "svg": "neato-icon.svg",
      "root-dir": "./custom-icons/neato-icon.svg"
    }
  ]
}
```

Once you're done, simply run `grunt` again to regenerate the fonts and scss partial. To edit the `_icons.scss` partial,
update `templates/scss.hbs`.

## Creating your own font

If you are developing a Video.js plugin that uses custom icons, you can also create a new font instead of modifying the
default font. Simply specify a new `font-name` and define the icons you want to include:

```json
{
  "font-name": "MyPluginFont",
  "root-dir": "./node_modules/material-design-icons/",
  "icons": [
    {
      "name": "av-perm",
      "svg": "action/svg/production/ic_perm_camera_mic_48px.svg"
    },
    {
      "name": "video-perm",
      "svg": "av/svg/production/ic_videocam_48px.svg"
    },
    {
      "name": "audio-perm",
      "svg": "av/svg/production/ic_mic_48px.svg"
    }
  ]
}
```
Generate the `MyPluginFont` font files using the `--custom-json` option:

```sh
$ grunt --custom-json=MyPluginFont.json
```

### Exclude default icons

By default, the regular Video.js icons are also included in the font. If you want to exclude these icons, when you're creating a Video.js plugin font for example, use the `--exclude-default` option.

Example:
```sh
$ grunt --custom-json=MyPluginFont.json --exclude-default
```
