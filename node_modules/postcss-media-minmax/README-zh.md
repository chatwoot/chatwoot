# PostCSS Media Minmax

[![Build Status](https://travis-ci.org/postcss/postcss-media-minmax.svg?branch=master)](https://travis-ci.org/postcss/postcss-media-minmax) 
[![NPM Downloads](https://img.shields.io/npm/dm/postcss-media-minmax.svg?style=flat)](https://www.npmjs.com/package/postcss-media-minmax) 
[![NPM Version](http://img.shields.io/npm/v/postcss-media-minmax.svg?style=flat)](https://www.npmjs.com/package/postcss-media-minmax) 
[![License](https://img.shields.io/npm/l/postcss-media-minmax.svg?style=flat)](http://opensource.org/licenses/MIT) 

> 写简单优雅的 Media Queries！

Media Queries 中的 `min-width` 和 `max-width` 等属性非常容易混淆，每次看到他们，我都想哭。现在[新的规范](https://drafts.csswg.org/mediaqueries/#mq-range-context)中，可以使用更加直观的 `>=`或`<=` 替代 media queries 中的 min-/max- 前缀。

**V2.1.0 开始支持 `>` 或 `<` 符号。**

这是一个实现 [CSS Media Queries Level 4](http://dev.w3.org/csswg/mediaqueries/) Polyfill 的插件，让你现在就可以使用这些特性，妈妈再也不用担心我记不住了，鹅妹子嘤！

 
[English](README.md)

-----

![Gif Demo](http://gtms02.alicdn.com/tps/i2/TB1UIjyGVXXXXcCaXXXx274FpXX-877-339.gif)


## 安装

    $ npm install postcss-media-minmax

## 快速开始

示例 1：

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

或者只需：

```js
var output = postcss(minmax())
  .process(css)
  .css
```

input.css：

```css
@media screen and (width >= 500px) and (width <= 1200px) {
  .bar {
    display: block;
  }
}
```

你将得到：

```css
@media screen and (min-width: 500px) and (max-width: 1200px) {
  .bar {
    display: block;
  }
}
```

## CSS 语法

### [语法](http://dev.w3.org/csswg/mediaqueries/#mq-syntax)

```
<mf-range> = <mf-name> [ '<' | '>' ]? '='? <mf-value>
           | <mf-value> [ '<' | '>' ]? '='? <mf-name>
           | <mf-value> '<' '='? <mf-name> '<' '='? <mf-value>
           | <mf-value> '>' '='? <mf-name> '>' '='? <mf-value>
```

![syntax](http://gtms03.alicdn.com/tps/i3/TB1Rje0HXXXXXXeXpXXccZJ0FXX-640-290.png)

PostCSS Media Minmax 目前并没有实现 `200px >= width` 或者 `200px <= width` 这样的语法，因为这样的语法可读性并不不是太好。

## [取值(Values)](http://dev.w3.org/csswg/mediaqueries/#values)
 
**The special values:**

* [<ratio>](http://dev.w3.org/csswg/mediaqueries/#typedef-ratio)

    <ratio> 是一个正（非零非负）的 <integer>（整型）取值，其后跟随0个或多个空白，接着跟随一个斜线（“/”），再跟随0个或多个空白，最后跟随一个正<integer>。

    ```css
    @media screen and (device-aspect-ratio: 16 /   9) {
      /* rules */
    }

    /* equivalent to */
    @media screen and (device-aspect-ratio: 16/9) {
      /* rules */
    }
    ```

* [<mq-boolean>](http://dev.w3.org/csswg/mediaqueries/#typedef-mq-boolean)

    <mq-boolean> 值是一个 0 或 1 的 <integer>（整型）取值。其他任何整数无效。注意， 在 CSS 中 -0 总是等价于 0 的，所以也作为一种有效的 <mq-boolean> 取值。  

    ```css
    @media screen and (grid: -0) {
      /* rules */
    }

    /* equivalent to */
    @media screen and (grid: 0) {
      /* rules */
    }
    ```

## 如何使用

### 简写

示例 1中同一个 Media features name 同时存在 `>=` 和 `<=` 时，可以简写为：

```css
@media screen and (500px <= width <= 1200px) {
  .bar {
    display: block;
  }
}
/* 或者 */
@media screen and (1200px >= width >= 500px) {
  .bar {
    display: block;
  }
}
```

都会得到一样的输出结果：

```css
@media screen and (min-width: 500px) and (max-width: 1200px) {
  .bar {
    display: block;
  }
}
```
**注意**：当 Media features name 在中间的时候，一定要保证两个 `<=` 或 `>=` 的方向一致，否则不会转换。

例如在下面的示例中，width 大于等于 500px 同时又大于等于 1200px，这在语法和逻辑上都是错误的。

```css
@media screen and (1200px <= width >= 500px) {
  .bar {
    display: block;
  }
}
```

### 支持的 Media features name

规范中目前以下属性支持 min-/max 前缀，PostCSS Media Minmax 全部支持自动转换。

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



### 支持在 `@custom-media` 中使用 & Node Watch

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


## 贡献

* 安装相关的依赖模块。
* 尊重编码风格（安装 [EditorConfig](http://editorconfig.org/)）。
* 在[test](test)目录添加测试用例。
* 运行测试。

```
$ git clone https://github.com/postcss/postcss-media-minmaxs.git
$ git checkout -b patch
$ npm install
$ npm test
```

## 致谢

* 感谢 PostCSS 作者 [Andrey Sitnik](https://github.com/ai)，带给我们如此简单易用的 CSS 语法解析工具。
* 感谢 [Tab Atkins Jr.](http://xanthir.com/contact/) 辛苦编写了 Media Queries Level 4 规范。
* 感谢 [@紫云飞](http://weibo.com/p/1005051708684567) 对本插件的建议和帮助。

## [Changelog](CHANGELOG.md)

## [License](LICENSE)
