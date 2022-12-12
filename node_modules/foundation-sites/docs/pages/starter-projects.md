---
title: Starter Projects
description: We have a few starter project templates that can be installed with the Foundation CLI. You can also download them manually!
video: 'lFrpnk0Oo_8'
---


Our project templates give you a solid... *Foundation* on which to start a new project. Both templates use the [Gulp](http://gulpjs.com) build system to automate the process of compiling Sass, processing JavaScript, copying files, and more.

## Basic Template

<div class="responsive-embed widescreen mb1">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/ofSZUKkjPRY" frameborder="0" allowfullscreen></iframe>
  <a id="docs-mobile-video-link" class="docs-mobile-video" target="_blank" href="https://youtu.be/ofSZUKkjPRY"></a>
</div>

Our basic project template is a lot like the Sass template from Foundation 5. The project has a flat directory structure and only compiles Sass. It's great if you want to quickly put together a simple project and only need to use Sass.

You can set up a basic project through the Foundation CLI with this command:

```bash
foundation new --framework sites --template basic
```

You can manually install the template with:
 ```bash
# Download the template with Git
git clone https://github.com/zurb/foundation-sites-template projectname

# Move to the project folder, and install dependencies
cd projectname
npm install

# Build the Sass files
npm start
```

Your project will be recompiled every time you save a Sass file in `dist/.

---

## ZURB Template

<div class="responsive-embed widescreen mb1">
  <iframe id="zurb-template-starter" data-linkable-video="3Uj74uJ3GSQ" width="500" height="315" src="https://www.youtube.com/embed/3Uj74uJ3GSQ?enablejsapi=1" enablejsapi="1" frameborder="0" allowfullscreen ></iframe>
  <a id="docs-mobile-video-link" class="docs-mobile-video" target="_blank" href="https://www.youtube.com/watch?v=3Uj74uJ3GSQ"></a>
</div>

The official ZURB Template includes not only Sass processing, but also JavaScript processing, Handlebars templating, and image compression. We use this exact template at ZURB for our client work!

You can set up an advanced project through the Foundation CLI with this command:

```bash
foundation new --framework sites --template zurb
```

You can manually install the template with:
```bash
# Download the ZURB template with Git
git clone https://github.com/zurb/foundation-zurb-template projectname

# Move to the project folder, and install dependencies
cd projectname
npm install

# Build the project
npm start
```

Once compiled, you project is viewable at: <a class="button primary" href="http://localhost:8000" target="_blank">http://localhost:8000</a>

The biggest difference between this and the basic template is the folder structure. In the ZURB Template, your project has a `src/` folder which contains your source files, and a separate `dist/` folder with your finished website. As you work on your project, Gulp continuously updates your `dist/` folder with new versions of files. To compile a production build, run `npm run build`.

To override or add to the default styles of the ZURB Template, in your project's `src/assets/scss/` folder
 - Change Sass variables in `_settings.scss`
 - Add custom SCSS and css to new files in the `components` folder then import those files at the bottom of `app.scss`

The `_settings.scss` and `app.scss` files are not changed when upgrading an existing project. As a result, you must manually edit your `_settings.scss` file to incorporate any Sass changes found [in the release notes](https://github.com/zurb/foundation-sites/releases).

### Features

Here's an overview of what the ZURB Template can do:

* **Asset Copying**

  Gulp will copy anything out of the `src/assets` folder as-is to the `assets` folder of your final project. Note that Sass files, JavaScript files, and images are *not* **part of this copying process, as they have their own steps.**
  

* **Page Compilation**

  The `src/` directory includes three folders used to create HTML pages: `pages/`, `layouts/`, and `partials/`. A flat file compiler called [Panini](panini.html) is used to process your project's various pages, inserting them into a common template, and injecting any HTML partials. This is done with a templating language called [Handlebars](http://handlebarsjs.com/).

  Panini has a dedicated page here in the docs that explains its various features. **[Learn more about Panini.](panini.html)**

* **Sass Compilation**

  Sass is compiled to CSS using [Libsass](http://sass-lang.com/libsass) (via [node-sass](https://github.com/sass/node-sass)). The main Sass file is under `src/assets/scss/app.scss`, and imports Foundation and Motion UI. Any new Sass partials you create should be in this folder as well.

  The CSS is output in the `nested` style, which is readable like normal CSS. A source map is also created, which can be read by developer tools such as the Chrome Web Inspector. When building for production, the CSS is also compressed with [clean-css](https://github.com/jakubpawlowicz/clean-css/issues), and pruned with [UnCSS](https://github.com/giakki/uncss). UnCSS scans the HTML of your pages and removes any CSS classes you didn't use.

* **JavaScript Compilation**

  JavaScript is transpiled using [Babel](https://babeljs.io) (with the [es2015 plugin](https://babeljs.io/docs/plugins/#es2015)) so you can use [ES2015 features](https://babeljs.io/learn-es2015/).
  The main Js file is under `src/assets/js/app.js`, and imports Foundation, jQuery and whatInput. You can import there installed packages and custom files, they will be included in the build.

  A source map is created that maps back to the original files. By default, the bundled `app.js` is uncompressed. When building for production, the file is run through [UglifyJS](https://github.com/mishoo/UglifyJS) for compression.

  The whole bundling process is handled by [webpack](https://webpack.js.org): it manages all assets and dependencies for you and compiles them into one single file. If you're unfamiliar with imports or module bundling, check out:
  * [What are ES6 imports](http://2ality.com/2014/09/es6-modules-final.html)
  * [Beginner’s guide to webpack](https://medium.com/javascript-training/beginner-s-guide-to-webpack-b1f1a3638460)
  * [Beginner’s guide to JavaScript Modules](https://medium.freecodecamp.org/javascript-modules-a-beginner-s-guide-783f7d7a5fcc).

* **Image Compression**

  By default, all images are copied as-is from `assets/img` to your `dist` folder. When building for production, images are run through [gulp-imagemin](https://github.com/sindresorhus/gulp-imagemin) for compression. The plugin supports JPEG, PNG, SVG, and GIF files.

* **BrowserSync**

  The template creates a [BrowserSync](http://www.browsersync.io/) server, which is at `http://localhost:8000`. Load this URL to see your compiled templates. While the server is running, any time you save a file, any pages you have open will automatically refresh, allowing you to see changes in real-time as you work.

* **Style Guide Creation**

  Under `src/styleguide` are two files to create a style guide for your project. The style guide is generated using Style Sherpa, a small plugin created by ZURB.

Style Sherpa has a dedicated page here in the docs that explains its various features. **[Learn more about Style Sherpa.](style-sherpa.html)**

### Tutorials

- [What the ZURB Stack Does](https://foundation.zurb.com/learn/foundation-6-zurb-stack-part-1.html) via ZURB
- [Overview of Foundation's ZURB Stack and File Structure](https://foundation.zurb.com/learn/foundation-6-stack-file-structure.html) via ZURB
- [All about the ZURB Template](https://zendev.com/2017/09/05/front-end-development-kickstarter-zurb-template.html#scss) via Kevin Ball
