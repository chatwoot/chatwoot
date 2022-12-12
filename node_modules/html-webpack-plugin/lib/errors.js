// @ts-nocheck
'use strict';
const PrettyError = require('pretty-error');
const prettyError = new PrettyError();
prettyError.withoutColors();
prettyError.skipPackage('html-plugin-evaluation');
prettyError.skipNodeFiles();
prettyError.skip(function (traceLine) {
  return traceLine.path === 'html-plugin-evaluation';
});

module.exports = function (err, context) {
  return {
    toHtml: function () {
      return 'Html Webpack Plugin:\n<pre>\n' + this.toString() + '</pre>';
    },
    toJsonHtml: function () {
      return JSON.stringify(this.toHtml());
    },
    toString: function () {
      try {
        return prettyError.render(err).replace(/webpack:\/\/\/\./g, context);
      } catch (e) {
        // This can sometimes fail. We don't know why, but returning the
        // original error is better than returning the error thrown by
        // pretty-error.
        return err;
      }
    }
  };
};
