# Pull Request Guidelines

We all love Pull Requests so if you have something you'd like to share with the community we'd be happy to help you out with contributing. But before you create your PR please read and understand the following. :heart:

## Code

If you're submitting a new animation, make sure that it looks identical in [all browsers that support CSS animations](http://caniuse.com/css-animation).

The animation styles should be put in an [SCSS](http://sass-lang.com/) file which you place in [scss/spinners/](https://github.com/tobiasahlin/SpinKit/blob/master/scss/spinners). It must also be imported in [scss/spinkit.scss](https://github.com/tobiasahlin/SpinKit/blob/master/scss/spinkit.scss). Carefully look at the existing spinners to make sure you follow the same conventions and that you list an example on top of the page exactly like the other spinners (we extract this when generating the HTML files). Don't use any browser prefixes as this will be added automatically to the generated CSS files by [autoprefixer](https://github.com/postcss/autoprefixer).

To generate the CSS and HTML files you need to have [node.js](http://nodejs.org/) installed on your system. After that you need to issue `npm install` from the SpinKit project directory to install [gulp](https://github.com/gulpjs/gulp) and other dependencies listed in `package.json`. After doing this you should be able to just call `gulp build` to generate the files. These files should be included in your pull requests.


## Style

Following the same code style makes all of our lives a bit easier, currently we ask that you use:

- 2 spaces for indenting
- No trailing spaces
- One trailing newline at the end of each file

If you use Sublime Text (or any other editor with the same capability) you can install EditorConfig (through [Sublime Package Control](https://sublime.wbond.net/installation)), which will pick up our project's `.editorconfig` and make your file conform to above rules on each save.
