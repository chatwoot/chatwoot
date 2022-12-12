"use strict";

exports.__esModule = true;
exports.default = void 0;

var _sourceMap = _interopRequireDefault(require("source-map"));

var _path = _interopRequireDefault(require("path"));

var _fs = _interopRequireDefault(require("fs"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fromBase64(str) {
  if (Buffer) {
    return Buffer.from(str, 'base64').toString();
  } else {
    return window.atob(str);
  }
}
/**
 * Source map information from input CSS.
 * For example, source map after Sass compiler.
 *
 * This class will automatically find source map in input CSS or in file system
 * near input file (according `from` option).
 *
 * @example
 * const root = postcss.parse(css, { from: 'a.sass.css' })
 * root.input.map //=> PreviousMap
 */


var PreviousMap = /*#__PURE__*/function () {
  /**
   * @param {string}         css    Input CSS source.
   * @param {processOptions} [opts] {@link Processor#process} options.
   */
  function PreviousMap(css, opts) {
    this.loadAnnotation(css);
    /**
     * Was source map inlined by data-uri to input CSS.
     *
     * @type {boolean}
     */

    this.inline = this.startWith(this.annotation, 'data:');
    var prev = opts.map ? opts.map.prev : undefined;
    var text = this.loadMap(opts.from, prev);
    if (text) this.text = text;
  }
  /**
   * Create a instance of `SourceMapGenerator` class
   * from the `source-map` library to work with source map information.
   *
   * It is lazy method, so it will create object only on first call
   * and then it will use cache.
   *
   * @return {SourceMapGenerator} Object with source map information.
   */


  var _proto = PreviousMap.prototype;

  _proto.consumer = function consumer() {
    if (!this.consumerCache) {
      this.consumerCache = new _sourceMap.default.SourceMapConsumer(this.text);
    }

    return this.consumerCache;
  }
  /**
   * Does source map contains `sourcesContent` with input source text.
   *
   * @return {boolean} Is `sourcesContent` present.
   */
  ;

  _proto.withContent = function withContent() {
    return !!(this.consumer().sourcesContent && this.consumer().sourcesContent.length > 0);
  };

  _proto.startWith = function startWith(string, start) {
    if (!string) return false;
    return string.substr(0, start.length) === start;
  };

  _proto.getAnnotationURL = function getAnnotationURL(sourceMapString) {
    return sourceMapString.match(/\/\*\s*# sourceMappingURL=(.*)\s*\*\//)[1].trim();
  };

  _proto.loadAnnotation = function loadAnnotation(css) {
    var annotations = css.match(/\/\*\s*# sourceMappingURL=(.*)\s*\*\//mg);

    if (annotations && annotations.length > 0) {
      // Locate the last sourceMappingURL to avoid picking up
      // sourceMappingURLs from comments, strings, etc.
      var lastAnnotation = annotations[annotations.length - 1];

      if (lastAnnotation) {
        this.annotation = this.getAnnotationURL(lastAnnotation);
      }
    }
  };

  _proto.decodeInline = function decodeInline(text) {
    var baseCharsetUri = /^data:application\/json;charset=utf-?8;base64,/;
    var baseUri = /^data:application\/json;base64,/;
    var uri = 'data:application/json,';

    if (this.startWith(text, uri)) {
      return decodeURIComponent(text.substr(uri.length));
    }

    if (baseCharsetUri.test(text) || baseUri.test(text)) {
      return fromBase64(text.substr(RegExp.lastMatch.length));
    }

    var encoding = text.match(/data:application\/json;([^,]+),/)[1];
    throw new Error('Unsupported source map encoding ' + encoding);
  };

  _proto.loadMap = function loadMap(file, prev) {
    if (prev === false) return false;

    if (prev) {
      if (typeof prev === 'string') {
        return prev;
      } else if (typeof prev === 'function') {
        var prevPath = prev(file);

        if (prevPath && _fs.default.existsSync && _fs.default.existsSync(prevPath)) {
          return _fs.default.readFileSync(prevPath, 'utf-8').toString().trim();
        } else {
          throw new Error('Unable to load previous source map: ' + prevPath.toString());
        }
      } else if (prev instanceof _sourceMap.default.SourceMapConsumer) {
        return _sourceMap.default.SourceMapGenerator.fromSourceMap(prev).toString();
      } else if (prev instanceof _sourceMap.default.SourceMapGenerator) {
        return prev.toString();
      } else if (this.isMap(prev)) {
        return JSON.stringify(prev);
      } else {
        throw new Error('Unsupported previous source map format: ' + prev.toString());
      }
    } else if (this.inline) {
      return this.decodeInline(this.annotation);
    } else if (this.annotation) {
      var map = this.annotation;
      if (file) map = _path.default.join(_path.default.dirname(file), map);
      this.root = _path.default.dirname(map);

      if (_fs.default.existsSync && _fs.default.existsSync(map)) {
        return _fs.default.readFileSync(map, 'utf-8').toString().trim();
      } else {
        return false;
      }
    }
  };

  _proto.isMap = function isMap(map) {
    if (typeof map !== 'object') return false;
    return typeof map.mappings === 'string' || typeof map._mappings === 'string';
  };

  return PreviousMap;
}();

var _default = PreviousMap;
exports.default = _default;
module.exports = exports.default;
//# sourceMappingURL=data:application/json;charset=utf8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbInByZXZpb3VzLW1hcC5lczYiXSwibmFtZXMiOlsiZnJvbUJhc2U2NCIsInN0ciIsIkJ1ZmZlciIsImZyb20iLCJ0b1N0cmluZyIsIndpbmRvdyIsImF0b2IiLCJQcmV2aW91c01hcCIsImNzcyIsIm9wdHMiLCJsb2FkQW5ub3RhdGlvbiIsImlubGluZSIsInN0YXJ0V2l0aCIsImFubm90YXRpb24iLCJwcmV2IiwibWFwIiwidW5kZWZpbmVkIiwidGV4dCIsImxvYWRNYXAiLCJjb25zdW1lciIsImNvbnN1bWVyQ2FjaGUiLCJtb3ppbGxhIiwiU291cmNlTWFwQ29uc3VtZXIiLCJ3aXRoQ29udGVudCIsInNvdXJjZXNDb250ZW50IiwibGVuZ3RoIiwic3RyaW5nIiwic3RhcnQiLCJzdWJzdHIiLCJnZXRBbm5vdGF0aW9uVVJMIiwic291cmNlTWFwU3RyaW5nIiwibWF0Y2giLCJ0cmltIiwiYW5ub3RhdGlvbnMiLCJsYXN0QW5ub3RhdGlvbiIsImRlY29kZUlubGluZSIsImJhc2VDaGFyc2V0VXJpIiwiYmFzZVVyaSIsInVyaSIsImRlY29kZVVSSUNvbXBvbmVudCIsInRlc3QiLCJSZWdFeHAiLCJsYXN0TWF0Y2giLCJlbmNvZGluZyIsIkVycm9yIiwiZmlsZSIsInByZXZQYXRoIiwiZnMiLCJleGlzdHNTeW5jIiwicmVhZEZpbGVTeW5jIiwiU291cmNlTWFwR2VuZXJhdG9yIiwiZnJvbVNvdXJjZU1hcCIsImlzTWFwIiwiSlNPTiIsInN0cmluZ2lmeSIsInBhdGgiLCJqb2luIiwiZGlybmFtZSIsInJvb3QiLCJtYXBwaW5ncyIsIl9tYXBwaW5ncyJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFBQTs7QUFDQTs7QUFDQTs7OztBQUVBLFNBQVNBLFVBQVQsQ0FBcUJDLEdBQXJCLEVBQTBCO0FBQ3hCLE1BQUlDLE1BQUosRUFBWTtBQUNWLFdBQU9BLE1BQU0sQ0FBQ0MsSUFBUCxDQUFZRixHQUFaLEVBQWlCLFFBQWpCLEVBQTJCRyxRQUEzQixFQUFQO0FBQ0QsR0FGRCxN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TCxDQUFleEMsSUFBZixDQUFQO0FBQ0QsT0FGTSxNQUVBO0FBQ0wsY0FBTSxJQUFJOEIsS0FBSixDQUNKLDZDQUE2QzlCLElBQUksQ0FBQ1YsUUFBTCxFQUR6QyxDQUFOO0FBRUQ7QUFDRixLQXJCRCxNQXFCTyxJQUFJLEtBQUtPLE1BQVQsRUFBaUI7QUFDdEIsYUFBTyxLQUFLd0IsWUFBTCxDQUFrQixLQUFLdEIsVUFBdkIsQ0FBUDtBQUNELEtBRk0sTUFFQSxJQUFJLEtBQUtBLFVBQVQsRUFBcUI7QUFDMUIsVUFBSUUsR0FBRyxHQUFHLEtBQUtGLFVBQWY7QUFDQSxVQUFJZ0MsSUFBSixFQUFVOUIsR0FBRyxHQUFHd0MsY0FBS0MsSUFBTCxDQUFVRCxjQUFLRSxPQUFMLENBQWFaLElBQWIsQ0FBVixFQUE4QjlCLEdBQTlCLENBQU47QUFFVixXQUFLMkMsSUFBTCxHQUFZSCxjQUFLRSxPQUFMLENBQWExQyxHQUFiLENBQVo7O0FBQ0EsVUFBSWdDLFlBQUdDLFVBQUgsSUFBaUJELFlBQUdDLFVBQUgsQ0FBY2pDLEdBQWQsQ0FBckIsRUFBeUM7QUFDdkMsZUFBT2dDLFlBQUdFLFlBQUgsQ0FBZ0JsQyxHQUFoQixFQUFxQixPQUFyQixFQUE4QlgsUUFBOUIsR0FBeUM0QixJQUF6QyxFQUFQO0FBQ0QsT0FGRCxNQUVPO0FBQ0wsZUFBTyxLQUFQO0FBQ0Q7QUFDRjtBQUNGLEc7O1NBRURvQixLLEdBQUEsZUFBT3JDLEdBQVAsRUFBWTtBQUNWLFFBQUksT0FBT0EsR0FBUCxLQUFlLFFBQW5CLEVBQTZCLE9BQU8sS0FBUDtBQUM3QixXQUFPLE9BQU9BLEdBQUcsQ0FBQzRDLFFBQVgsS0FBd0IsUUFBeEIsSUFBb0MsT0FBTzVDLEdBQUcsQ0FBQzZDLFNBQVgsS0FBeUIsUUFBcEU7QUFDRCxHOzs7OztlQUdZckQsVyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBtb3ppbGxhIGZyb20gJ3NvdXJjZS1tYXAnXG5pbXBvcnQgcGF0aCBmcm9tICdwYXRoJ1xuaW1wb3J0IGZzIGZyb20gJ2ZzJ1xuXG5mdW5jdGlvbiBmcm9tQmFzZTY0IChzdHIpIHtcbiAgaWYgKEJ1ZmZlcikge1xuICAgIHJldHVybiBCdWZmZXIuZnJvbShzdHIsICdiYXNlNjQnKS50b1N0cmluZygpXG4gIH0gZWxzZSB7XG4gICAgcmV0dXJuIHdpbmRvdy5hdG9iKHN0cilcbiAgfVxufVxuXG4vKipcbiAqIFNvdXJjZSBtYXAgaW5mb3JtYXRpb24gZnJvbSBpbnB1dCBDU1MuXG4gKiBGb3IgZXhhbXBsZSwgc291cmNlIG1hcCBhZnRlciBTYXNzIGNvbXBpbGVyLlxuICpcbiAqIFRoaXMgY2xhc3Mgd2lsbCBhdXRvbWF0aWNhbGx5IGZpbmQgc291cmNlIG1hcCBpbiBpbnB1dCBDU1Mgb3IgaW4gZmlsZSBzeXN0ZW1cbiAqIG5lYXIgaW5wdXQgZmlsZSAoYWNjb3JkaW5nIGBmcm9tYCBvcHRpb24pLlxuICpcbiAqIEBleGFtcGxlXG4gKiBjb25zdCByb290ID0gcG9zdGNzcy5wYXJzZShjc3MsIHsgZnJvbTogJ2Euc2Fzcy5jc3MnIH0pXG4gKiByb290LmlucHV0Lm1hcCAvLz0+IFByZXZpb3VzTWFwXG4gKi9cbmNsYXNzIFByZXZpb3VzTWFwIHtcbiAgLyoqXG4gICAqIEBwYXJhbSB7c3RyaW5nfSAgICAgICAgIGNzcyAgICBJbnB1dCBDU1Mgc291cmNlLlxuICAgKiBAcGFyYW0ge3Byb2Nlc3NPcHRpb25zfSBbb3B0c10ge0BsaW5rIFByb2Nlc3NvciNwcm9jZXNzfSBvcHRpb25zLlxuICAgKi9cbiAgY29uc3RydWN0b3IgKGNzcywgb3B0cykge1xuICAgIHRoaXMubG9hZEFubm90YXRpb24oY3NzKVxuICAgIC8qKlxuICAgICAqIFdhcyBzb3VyY2UgbWFwIGlubGluZWQgYnkgZGF0YS11cmkgdG8gaW5wdXQgQ1NTLlxuICAgICAqXG4gICAgICogQHR5cGUge2Jvb2xlYW59XG4gICAgICovXG4gICAgdGhpcy5pbmxpbmUgPSB0aGlzLnN0YXJ0V2l0aCh0aGlzLmFubm90YXRpb24sICdkYXRhOicpXG5cbiAgICBsZXQgcHJldiA9IG9wdHMubWFwID8gb3B0cy5tYXAucHJldiA6IHVuZGVmaW5lZFxuICAgIGxldCB0ZXh0ID0gdGhpcy5sb2FkTWFwKG9wdHMuZnJvbSwgcHJldilcbiAgICBpZiAodGV4dCkgdGhpcy50ZXh0ID0gdGV4dFxuICB9XG5cbiAgLyoqXG4gICAqIENyZWF0ZSBhIGluc3RhbmNlIG9mIGBTb3VyY2VNYXBHZW5lcmF0b3JgIGNsYXNzXG4gICAqIGZyb20gdGhlIGBzb3VyY2UtbWFwYCBsaWJyYXJ5IHRvIHdvcmsgd2l0aCBzb3VyY2UgbWFwIGluZm9ybWF0aW9uLlxuICAgKlxuICAgKiBJdCBpcyBsYXp5IG1ldGhvZCwgc28gaXQgd2lsbCBjcmVhdGUgb2JqZWN0IG9ubHkgb24gZmlyc3QgY2FsbFxuICAgKiBhbmQgdGhlbiBpdCB3aWxsIHVzZSBjYWNoZS5cbiAgICpcbiAgICogQHJldHVybiB7U291cmNlTWFwR2VuZXJhdG9yfSBPYmplY3Qgd2l0aCBzb3VyY2UgbWFwIGluZm9ybWF0aW9uLlxuICAgKi9cbiAgY29uc3VtZXIgKCkge1xuICAgIGlmICghdGhpcy5jb25zdW1lckNhY2hlKSB7XG4gICAgICB0aGlzLmNvbnN1bWVyQ2FjaGUgPSBuZXcgbW96aWxsYS5Tb3VyY2VNYXBDb25zdW1lcih0aGlzLnRleHQpXG4gICAgfVxuICAgIHJldHVybiB0aGlzLmNvbnN1bWVyQ2FjaGVcbiAgfVxuXG4gIC8qKlxuICAgKiBEb2VzIHNvdXJjZSBtYXAgY29udGFpbnMgYHNvdXJjZXNDb250ZW50YCB3aXRoIGlucHV0IHNvdXJjZSB0ZXh0LlxuICAgKlxuICAgKiBAcmV0dXJuIHtib29sZWFufSBJcyBgc291cmNlc0NvbnRlbnRgIHByZXNlbnQuXG4gICAqL1xuICB3aXRoQ29udGVudCAoKSB7XG4gICAgcmV0dXJuICEhKHRoaXMuY29uc3VtZXIoKS5zb3VyY2VzQ29udGVudCAmJlxuICAgICAgICAgICAgICB0aGlzLmNvbnN1bWVyKCkuc291cmNlc0NvbnRlbnQubGVuZ3RoID4gMClcbiAgfVxuXG4gIHN0YXJ0V2l0aCAoc3RyaW5nLCBzdGFydCkge1xuICAgIGlmICghc3RyaW5nKSByZXR1cm4gZmFsc2VcbiAgICByZXR1cm4gc3RyaW5nLnN1YnN0cigwLCBzdGFydC5sZW5ndGgpID09PSBzdGFydFxuICB9XG5cbiAgZ2V0QW5ub3RhdGlvblVSTCAoc291cmNlTWFwU3RyaW5nKSB7XG4gICAgcmV0dXJuIHNvdXJjZU1hcFN0cmluZ1xuICAgICAgLm1hdGNoKC9cXC9cXCpcXHMqIyBzb3VyY2VNYXBwaW5nVVJMPSguKilcXHMqXFwqXFwvLylbMV1cbiAgICAgIC50cmltKClcbiAgfVxuXG4gIGxvYWRBbm5vdGF0aW9uIChjc3MpIHtcbiAgICBsZXQgYW5ub3RhdGlvbnMgPSBjc3MubWF0Y2goL1xcL1xcKlxccyojIHNvdXJjZU1hcHBpbmdVUkw9KC4qKVxccypcXCpcXC8vbWcpXG5cbiAgICBpZiAoYW5ub3RhdGlvbnMgJiYgYW5ub3RhdGlvbnMubGVuZ3RoID4gMCkge1xuICAgICAgLy8gTG9jYXRlIHRoZSBsYXN0IHNvdXJjZU1hcHBpbmdVUkwgdG8gYXZvaWQgcGlja2luZyB1cFxuICAgICAgLy8gc291cmNlTWFwcGluZ1VSTHMgZnJvbSBjb21tZW50cywgc3RyaW5ncywgZXRjLlxuICAgICAgbGV0IGxhc3RBbm5vdGF0aW9uID0gYW5ub3RhdGlvbnNbYW5ub3RhdGlvbnMubGVuZ3RoIC0gMV1cbiAgICAgIGlmIChsYXN0QW5ub3RhdGlvbikge1xuICAgICAgICB0aGlzLmFubm90YXRpb24gPSB0aGlzLmdldEFubm90YXRpb25VUkwobGFzdEFubm90YXRpb24pXG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgZGVjb2RlSW5saW5lICh0ZXh0KSB7XG4gICAgbGV0IGJhc2VDaGFyc2V0VXJpID0gL15kYXRhOmFwcGxpY2F0aW9uXFwvanNvbjtjaGFyc2V0PXV0Zi0/ODtiYXNlNjQsL1xuICAgIGxldCBiYXNlVXJpID0gL15kYXRhOmFwcGxpY2F0aW9uXFwvanNvbjtiYXNlNjQsL1xuICAgIGxldCB1cmkgPSAnZGF0YTphcHBsaWNhdGlvbi9qc29uLCdcblxuICAgIGlmICh0aGlzLnN0YXJ0V2l0aCh0ZXh0LCB1cmkpKSB7XG4gICAgICByZXR1cm4gZGVjb2RlVVJJQ29tcG9uZW50KHRleHQuc3Vic3RyKHVyaS5sZW5ndGgpKVxuICAgIH1cblxuICAgIGlmIChiYXNlQ2hhcnNldFVyaS50ZXN0KHRleHQpIHx8IGJhc2VVcmkudGVzdCh0ZXh0KSkge1xuICAgICAgcmV0dXJuIGZyb21CYXNlNjQodGV4dC5zdWJzdHIoUmVnRXhwLmxhc3RNYXRjaC5sZW5ndGgpKVxuICAgIH1cblxuICAgIGxldCBlbmNvZGluZyA9IHRleHQubWF0Y2goL2RhdGE6YXBwbGljYXRpb25cXC9qc29uOyhbXixdKyksLylbMV1cbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1Vuc3VwcG9ydGVkIHNvdXJjZSBtYXAgZW5jb2RpbmcgJyArIGVuY29kaW5nKVxuICB9XG5cbiAgbG9hZE1hcCAoZmlsZSwgcHJldikge1xuICAgIGlmIChwcmV2ID09PSBmYWxzZSkgcmV0dXJuIGZhbHNlXG5cbiAgICBpZiAocHJldikge1xuICAgICAgaWYgKHR5cGVvZiBwcmV2ID09PSAnc3RyaW5nJykge1xuICAgICAgICByZXR1cm4gcHJldlxuICAgICAgfSBlbHNlIGlmICh0eXBlb2YgcHJldiA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICBsZXQgcHJldlBhdGggPSBwcmV2KGZpbGUpXG4gICAgICAgIGlmIChwcmV2UGF0aCAmJiBmcy5leGlzdHNTeW5jICYmIGZzLmV4aXN0c1N5bmMocHJldlBhdGgpKSB7XG4gICAgICAgICAgcmV0dXJuIGZzLnJlYWRGaWxlU3luYyhwcmV2UGF0aCwgJ3V0Zi04JykudG9TdHJpbmcoKS50cmltKClcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgICAnVW5hYmxlIHRvIGxvYWQgcHJldmlvdXMgc291cmNlIG1hcDogJyArIHByZXZQYXRoLnRvU3RyaW5nKCkpXG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSBpZiAocHJldiBpbnN0YW5jZW9mIG1vemlsbGEuU291cmNlTWFwQ29uc3VtZXIpIHtcbiAgICAgICAgcmV0dXJuIG1vemlsbGEuU291cmNlTWFwR2VuZXJhdG9yLmZyb21Tb3VyY2VNYXAocHJldikudG9TdHJpbmcoKVxuICAgICAgfSBlbHNlIGlmIChwcmV2IGluc3RhbmNlb2YgbW96aWxsYS5Tb3VyY2VNYXBHZW5lcmF0b3IpIHtcbiAgICAgICAgcmV0dXJuIHByZXYudG9TdHJpbmcoKVxuICAgICAgfSBlbHNlIGlmICh0aGlzLmlzTWFwKHByZXYpKSB7XG4gICAgICAgIHJldHVybiBKU09OLnN0cmluZ2lmeShwcmV2KVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKFxuICAgICAgICAgICdVbnN1cHBvcnRlZCBwcmV2aW91cyBzb3VyY2UgbWFwIGZvcm1hdDogJyArIHByZXYudG9TdHJpbmcoKSlcbiAgICAgIH1cbiAgICB9IGVsc2UgaWYgKHRoaXMuaW5saW5lKSB7XG4gICAgICByZXR1cm4gdGhpcy5kZWNvZGVJbmxpbmUodGhpcy5hbm5vdGF0aW9uKVxuICAgIH0gZWxzZSBpZiAodGhpcy5hbm5vdGF0aW9uKSB7XG4gICAgICBsZXQgbWFwID0gdGhpcy5hbm5vdGF0aW9uXG4gICAgICBpZiAoZmlsZSkgbWFwID0gcGF0aC5qb2luKHBhdGguZGlybmFtZShmaWxlKSwgbWFwKVxuXG4gICAgICB0aGlzLnJvb3QgPSBwYXRoLmRpcm5hbWUobWFwKVxuICAgICAgaWYgKGZzLmV4aXN0c1N5bmMgJiYgZnMuZXhpc3RzU3luYyhtYXApKSB7XG4gICAgICAgIHJldHVybiBmcy5yZWFkRmlsZVN5bmMobWFwLCAndXRmLTgnKS50b1N0cmluZygpLnRyaW0oKVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgaXNNYXAgKG1hcCkge1xuICAgIGlmICh0eXBlb2YgbWFwICE9PSAnb2JqZWN0JykgcmV0dXJuIGZhbHNlXG4gICAgcmV0dXJuIHR5cGVvZiBtYXAubWFwcGluZ3MgPT09ICdzdHJpbmcnIHx8IHR5cGVvZiBtYXAuX21hcHBpbmdzID09PSAnc3RyaW5nJ1xuICB9XG59XG5cbmV4cG9ydCBkZWZhdWx0IFByZXZpb3VzTWFwXG4iXSwiZmlsZSI6InByZXZpb3VzLW1hcC5qcyJ9
