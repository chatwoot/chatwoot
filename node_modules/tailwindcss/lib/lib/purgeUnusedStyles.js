"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = purgeUnusedUtilities;

var _lodash = _interopRequireDefault(require("lodash"));

var _postcss = _interopRequireDefault(require("postcss"));

var _postcssPurgecss = _interopRequireDefault(require("@fullhuman/postcss-purgecss"));

var _log = _interopRequireDefault(require("../util/log"));

var _htmlTags = _interopRequireDefault(require("html-tags"));

var _featureFlags = require("../featureFlags");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function removeTailwindMarkers(css) {
  css.walkAtRules('tailwind', rule => rule.remove());
  css.walkComments(comment => {
    switch (comment.text.trim()) {
      case 'tailwind start base':
      case 'tailwind end base':
      case 'tailwind start components':
      case 'tailwind start utilities':
      case 'tailwind end components':
      case 'tailwind end utilities':
        comment.remove();
        break;

      default:
        break;
    }
  });
}

function purgeUnusedUtilities(config, configChanged) {
  const purgeEnabled = _lodash.default.get(config, 'purge.enabled', config.purge !== false && config.purge !== undefined && process.env.NODE_ENV === 'production');

  if (!purgeEnabled) {
    return removeTailwindMarkers;
  } // Skip if `purge: []` since that's part of the default config


  if (Array.isArray(config.purge) && config.purge.length === 0) {
    if (configChanged) {
      _log.default.warn(['Tailwind is not purging unused styles because no template paths have been provided.', 'If you have manually configured PurgeCSS outside of Tailwind or are deliberately not removing unused styles, set `purge: false` in your Tailwind config file to silence this warning.', 'https://tailwindcss.com/docs/controlling-file-size/#removing-unused-css']);
    }

    return removeTailwindMarkers;
  }

  return (0, _postcss.default)([function (css) {
    const mode = _lodash.default.get(config, 'purge.mode', (0, _featureFlags.flagEnabled)(config, 'purgeLayersByDefault') ? 'layers' : 'conservative');

    if (!['all', 'layers', 'conservative'].includes(mode)) {
      throw new Error('Purge `mode` must be one of `layers` or `all`.');
    }

    if (mode === 'all') {
      return;
    }

    if (mode === 'conservative') {
      if (configChanged) {
        _log.default.warn(['The `conservative` purge mode will be removed in Tailwind 2.0.', 'Please switch to the new `layers` mode instead.']);
      }
    }

    const layers = mode === 'conservative' ? ['utilities'] : _lodash.default.get(config, 'purge.layers', ['base', 'components', 'utilities']);
    css.walkComments(comment => {
      switch (comment.text.trim()) {
        case `purgecss start ignore`:
          comment.before(_postcss.default.comment({
            text: 'purgecss end ignore'
          }));
          break;

        case `purgecss end ignore`:
          comment.before(_postcss.default.comment({
            text: 'purgecss end ignore'
          }));
          comment.text = 'purgecss start ignore';
          break;

        default:
          break;
      }

      layers.forEach(layer => {
        switch (comment.text.trim()) {
          case `tailwind start ${layer}`:
            comment.text = 'purgecss end ignore';
            break;

          case `tailwind end ${layer}`:
            comment.text = 'purgecss start ignore';
            break;

          default:
            break;
        }
      });
    });
    css.prepend(_postcss.default.comment({
      text: 'purgecss start ignore'
    }));
    css.append(_postcss.default.comment({
      text: 'purgecss end ignore'
    }));
  }, removeTailwindMarkers, (0, _postcssPurgecss.default)({
    content: Array.isArray(config.purge) ? config.purge : config.purge.content,
    defaultExtractor: content => {
      // Capture as liberally as possible, including things like `h-(screen-1.5)`
      const broadMatches = content.match(/[^<>"'`\s]*[^<>"'`\s:]/g) || [];
      const broadMatchesWithoutTrailingSlash = broadMatches.map(match => _lodash.default.trimEnd(match, '\\')); // Capture classes within other delimiters like .block(class="w-1/2") in Pug

      const innerMatches = content.match(/[^<>"'`\s.(){}[\]#=%]*[^<>"'`\s.(){}[\]#=%:]/g) || [];
      const matches = broadMatches.concat(broadMatchesWithoutTrailingSlash).concat(innerMatches);

      if (_lodash.default.get(config, 'purge.preserveHtmlElements', true)) {
        return [..._htmlTags.default].concat(matches);
      } else {
        return matches;
      }
    },
    ...config.purge.options
  })]);
}