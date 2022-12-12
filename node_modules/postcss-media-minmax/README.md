# PostCSS Media Minmax

[![CSS Standard Status](https://cssdb.org/badge/media-query-ranges.svg)](https://cssdb.org/#media-query-ranges)
[![Build Status](https://travis-ci.org/postcss/postcss-media-minmax.svg?branch=master)](https://travis-ci.org/postcss/postcss-media-minmax) 
[![NPM Downloads](https://img.shields.io/npm/dm/postcss-media-minmax.svg?style=flat)](https://www.npmjs.com/package/postcss-media-minmax) 
[![NPM Version](https://img.shields.io/npm/v/postcss-media-minmax.svg?style=flat)](https://www.npmjs.com/package/postcss-media-minmax) 
[![License](https://img.shields.io/npm/l/postcss-media-minmax.svg?style=flat)](https://opensource.org/licenses/MIT) 

> Writing simple and graceful media queries!

The `min-width`, `max-width` and many other properties of media queries are really confusing. I want to cry every time I see them. But right now according to the new specs, you can use more intuitive `<=` or `>=` to replace the  `min-`/`max-` prefixes in media queries.

V2.1.0 began to support `>` or `<` symbol.

This is a polyfill plugin which supports [CSS Media Queries Level 4](https://drafts.csswg.org/mediaqueries/#mq-range-context) and gives you access to the new features right away. Mom will never worry about my study any more. So amazing!


[简体中文](README-zh.md)

-----

![Gif Demo](https://gtms02.alicdn.com/tps/i2/TB1UIjyGVXXXXcCaXXXx274FpXX-877-339.gif)


## Installation

    $ npm install postcss-media-minmax

## Quick Start

Example 1:

```js
var fs = require('fs')
var postcss = require('postcss')
var minmax = require('postcss-media-minmax')

var css = fs.readFileSync('input.css', 'utf8')

var output = postcss()
  .use(minmax())
  .process(css)
  .css
  
console.log('\n====>Output CSS:\n', output)  
```

Or just:

```js
var output = postcss(minmax())
  .process(css)
  .css
```

input.css:

```css
@media screen and (width >= 500px) and (width <= 1200px) {
  .bar {
    display: block;
  }
}
```

You will get:

```css
@media screen and (min-width: 500px) and (max-width: 1200px) {
  .bar {
    display: block;
  }
}
```

## CSS syntax

### [Syntax](https://drafts.csswg.org/mediaqueries/#mq-range-context)

```
<mf-range> = <mf-name> [ '<' | '>' ]? '='? <mf-value>
           | <mf-value> [ '<' | '>' ]? '='? <mf-name>
           | <mf-value> '<' '='? <mf-name> '<' '='? <mf-value>
           | <mf-value> '>' '='? <mf-name> '>' '='? <mf-value>
```

![syntax](https://gtms03.alicdn.com/tps/i3/TB1Rje0HXXXXXXeXpXXccZJ0FXX-640-290.png)

PostCSS Media Minmax hasn't implemented syntax such as `200px > = width` or `200px < = width` currently because its readability is not good enough yet.

## [Values](https://drafts.csswg.org/mediaqueries/#values)
 
**The special values:**

* [<ratio>](https://drafts.csswg.org/mediaqueries/#typedef-ratio)

    The <ratio> value type is a positive (not zero or negative) <integer> followed by optional whitespace, followed by a solidus ('/'), followed by optional whitespace, followed by a positive <integer>. <ratio>s can be ordered or compared by transforming them into the number obtained by dividing their first <integer> by their second <integer>.

    ```css
    @media screen and (device-aspect-ratio: 16 /   9) {
      /* rules */
    }

    /* equivalent to */
    @media screen and (device-aspect-ratio: 16/9) {
      /* rules */
    }
    ```

* [<mq-boolean>](https://drafts.csswg.org/mediaqueries/#typedef-mq-boolean)

    The <mq-boolean> value type is an <integer> with the value 0 or 1. Any other integer value is invalid. Note that -0 is always equivalent to 0 in CSS, and so is also accepted as a valid <mq-boolean> value. 

    ```css
    @media screen and (grid: -0) {
      /* rules */
    }

    /* equivalent to */
    @media screen and (grid: 0) {
      /* rules */
    }
    ```

## How to use

### Shorthand

In Example 1, if a feature has both `>=` and `<=` logic, it can be written as follows:

```css
@media screen and (500px <= width <= 1200px) {
  .bar {
    display: block;
  }
}
/* Or */
@media screen and (1200px >= width >= 500px) {
  .bar {
    display: block;
  }
}
```

Which will output:

```css
@media screen and (min-width: 500px) and (max-width: 1200px) {
  .bar {
    display: block;
  }
}
```

**Note**: When the media feature name is in the middle, we must ensure that two `<=` or `>=` are in the same direction, otherwise which will not be converted.

E.g. in the example below, `width` is greater than or equal to 500px and is greater than or equal to 1200px, which is the wrong in both grammar and logic.


```css
@media screen and (1200px <= width >= 500px) {
  .bar {
    display: block;
  }
}
```

### Media feature names

The following properties support the `min-`/`max-` prefixes in the specifications at present, and will be automatically converted by PostCSS Media Minmax.

* `width`
* `height`
* `device-width`
* `device-height`
* `aspect-ratio`
* `device-aspect-ratio`
* `color`
* `color-index`
* `monochrome`
* `resolution`



### Using with `@custom-media` & Node Watch

```js
var fs = require('fs')
var chokidar = require('chokidar')
var postcss = require('postcss')
var minmax = require('postcss-media-minmax')
var customMedia = require('postcss-custom-media')

var src = 'input.css'

console.info('Watching…\nModify the input.css and save.')


chokidar.watch(src, {
  ignored: /[\/\\]\./,
  persistent: true
}).on('all',
  function(event, path, stats) {
    var css = fs.readFileSync(src, 'utf8')
    var output = postcss()
      .use(customMedia())
      .use(minmax())
      .process(css)
      .css;
    fs.writeFileSync('output.css', output)
  })

```


input.css:

```css
@custom-media --foo (width >= 20em) and (width <= 50em);
@custom-media --bar (height >= 300px) and (height <= 600px);

@media (--foo) and (--bar) {
  
}
```

output.css:

```css
@media (min-width: 20em) and (max-width: 50em) and (min-height: 300px) and (max-height: 600px) {
  
}
```

### Grunt

```js
module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    postcss: {
      options: {
        processors: [
          require('autoprefixer-core')({ browsers: ['> 0%'] }).postcss, //Other plugin
          require('postcss-media-minmax')(),
        ]
      },
      dist: {
        src: ['src/*.css'],
        dest: 'build/grunt.css'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-postcss');

  grunt.registerTask('default', ['postcss']);
}
```

### Gulp

```js
var gulp = require('gulp');
var rename = require('gulp-rename');
var postcss = require('gulp-postcss');
var selector = require('postcss-media-minmax')
var autoprefixer = require('autoprefixer-core')

gulp.task('default', function () {
    var processors = [
        autoprefixer({ browsers: ['> 0%'] }), //Other plugin
        minmax()
    ];
    gulp.src('src/*.css')
        .pipe(postcss(processors))
        .pipe(rename('gulp.css'))
        .pipe(gulp.dest('build'))
});
gulp.watch('src/*.css', ['default']);
```


## Contributing

* Install all the dependent modules.
* Respect the coding style (Use [EditorConfig](https://editorconfig.org/)).
* Add test cases in the [test](test) directory.
* Run the test cases.

```
$ git clone https://github.com/postcss/postcss-media-minmaxs.git
$ git checkout -b patch
$ npm install
$ npm test
```

## Acknowledgements

* Thank the author of PostCSS [Andrey Sitnik](https://github.com/ai) for giving us such simple and easy CSS syntax analysis tools.

* Thank [Tab Atkins Jr.](https://www.xanthir.com/contact/) for writing the specs of Media Queries Level 4.

* Thank [ziyunfei](https://weibo.com/p/1005051708684567) for suggestions and help of this plugin.


## [Changelog](CHANGELOG.md)

## [License](LICENSE)
