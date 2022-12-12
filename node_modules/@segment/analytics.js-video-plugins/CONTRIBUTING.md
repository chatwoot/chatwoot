# Developing analytics.js-video-plaugins

 - [Development Environment Setup](#development-setup)
 - [Project Structure](#project-structure)
 - [Code Conventions](#code-conventions)
 - [Git Commit Guidelines](#git-commit-guidelines)
 - [Testing Locally](#testing-locally)

## Development Setup

To get started, you'll need to have the following tools available in your local development environment:

* [Git](http://git-scm.com/): The [Github Guide to
  Installing Git][https://help.github.com/articles/set-up-git/] is a good source of information.

* [Node.js (v8 or higher)](http://nodejs.org)

* [Yarn](https://yarnpkg.com): We use Yarn to install our Node.js module dependencies. See the detailed [installation instructions](https://yarnpkg.com/en/docs/install#mac-stable).

* [Prettier](https://prettier.io/): All of our code formatting is handled by Prettier. We recommend installing Prettier as an integration into your [editor](https://prettier.io/docs/en/editors.html) of choice.

Once you have these dependencies in place, feel free to clone this repo locally to get started:

```bash
$ git clone https://github.com/segmentio/analytics.js-video-plugins
$ cd analytics.js-plugins
```

## Project Structure

Each plugin is stored in it's own directory within the `/plugins` directory. They must each have at least an `index.js` file to store the Plugin class and an `index.test.js` file to store corresponding unit tests. Please also ensure you add a `README` to store any information that could be useful about plugin nuiances for future developers.

## Code Conventions

The project uses [`prettier`](https://github.com/prettier/prettier) as it's code formatting standard.

The project also uses Babel to support the use of modern JS syntax. **Please Note:** the project does NOT yet use [babel-polyfill](https://babeljs.io/docs/en/babel-polyfill/). This is to ensure that the bundle size stay as small as possible. If you would like to use new ES5+ built-ins such as `Object.assign`, `Array.from`, etc. please load them in as individual [ponyfills](https://github.com/sindresorhus/ponyfill). **Please ensure you explicitly use ponyfills instead of polyfills!** These plugins are distributed as libraries and cannot pollute the global scope.

The project already ponyfills [`window.fetch`](https://github.com/developit/unfetch) if you need to make async requests. It does not support using `async/await`, please use `Promises`.

All plugins are written and exported as JS [Classes](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes).

## Testing Locally
If you'd like to test your plugin in a browser, simply run `yarn cdn`. This will build and distribute the plugins as a UMD module ready to be loaded into the browser. You can access the bundle at `http://localhost:8080/index.html`. Feel free to copy/paste this `script` tag into a test website: 

```
<script>
        !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","reset","group","track","ready","alias","debug","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t,e){var n=document.createElement("script");n.type="text/javascript";n.async=!0;n.src="https://cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var a=document.getElementsByTagName("script")[0];a.parentNode.insertBefore(n,a);analytics._loadOptions=e};analytics.SNIPPET_VERSION="4.1.0";
        analytics.load("Segment write key");
        }}();
</script>
<script src='http://localhost:8080/index.html' type='text/javascript'></script>
```

All plugins will be available at runtime at `window.videoPlugins.<PLUGIN_NAME>`.