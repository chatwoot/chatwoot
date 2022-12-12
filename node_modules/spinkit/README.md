# [SpinKit](http://tobiasahlin.com/spinkit/)

Simple loading spinners animated with CSS. See [demo](http://tobiasahlin.com/spinkit/). SpinKit uses hardware accelerated (`translate` and `opacity`) CSS animations to create smooth and easily customizable animations. 

## Usage

### Regular CSS

Grab the HTML and CSS for a spinner from the example files, or add SpinKit directly to your project with `bower`:

```bash
$ bower install spinkit
```

or npm:

```bash
$ npm install spinkit
```

### SCSS

If you're using SCSS you can include specific spinners (rather than all of them) by importing them one by one:

```scss
@import '../bower_components/spinkit/scss/spinners/1-rotating-plane',
        '../bower_components/spinkit/scss/spinners/3-wave';
```

You currently need to use an [autoprefixer](https://github.com/postcss/autoprefixer) if you want to support all browsers. If you're compiling your SCSS with gulp you can use [gulp-autoprefixer](https://github.com/sindresorhus/gulp-autoprefixer), and [grunt-autoprefixer](https://github.com/nDmitry/grunt-autoprefixer) if you use grunt.

Variables that can be overridden are listed in [scss/_variables.scss](https://github.com/tobiasahlin/SpinKit/blob/master/scss/_variables.scss).

## Web browser compatibility

CSS animations are supported in the latest version of all major browsers, and browsers with `animation` support make up [almost 90% of all usage](http://caniuse.com/#feat=css-animation). If you need to support IE9 and below, however, this section is for you.

### Implementing a fallback spinner

How do you know if you need to provide a fallback? You can easily check for animation support with [Modernizr](http://modernizr.com), or manually check for the `animation` property, and replace the spinner with a GIF if it's not supported:

```javascript
function browserSupportsCSSProperty(propertyName) {
  var elm = document.createElement('div');
  propertyName = propertyName.toLowerCase();

  if (elm.style[propertyName] != undefined)
    return true;

  var propertyNameCapital = propertyName.charAt(0).toUpperCase() + propertyName.substr(1),
    domPrefixes = 'Webkit Moz ms O'.split(' ');

  for (var i = 0; i < domPrefixes.length; i++) {
    if (elm.style[domPrefixes[i] + propertyNameCapital] != undefined)
      return true;
  }

  return false;
}
```

Use it to check for `animation` support:

```javascript
if (!browserSupportsCSSProperty('animation')) {
  // fallback…
}
```

## Contributing

See [CONTRIBUTING.md](https://github.com/tobiasahlin/SpinKit/blob/master/CONTRIBUTING.md) for details.
