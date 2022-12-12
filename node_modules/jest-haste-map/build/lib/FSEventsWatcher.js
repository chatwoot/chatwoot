'use strict';

function _events() {
  const data = require('events');

  _events = function () {
    return data;
  };

  return data;
}

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _anymatch() {
  const data = _interopRequireDefault(require('anymatch'));

  _anymatch = function () {
    return data;
  };

  return data;
}

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _micromatch() {
  const data = _interopRequireDefault(require('micromatch'));

  _micromatch = function () {
    return data;
  };

  return data;
}

function _walker() {
  const data = _interopRequireDefault(require('walker'));

  _walker = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

// eslint-disable-next-line @typescript-eslint/prefer-ts-expect-error
// @ts-ignore: this is for CI which runs linux and might not have this
let fsevents = null;

try {
  fsevents = require('fsevents');
} catch {
  // Optional dependency, only supported on Darwin.
}

const CHANGE_EVENT = 'change';
const DELETE_EVENT = 'delete';
const ADD_EVENT = 'add';
const ALL_EVENT = 'all';

/**
 * Export `FSEventsWatcher` class.
 * Watches `dir`.
 */
class FSEventsWatcher extends _events().EventEmitter {
  static isSupported() {
    return fsevents !== null;
  }

  static normalizeProxy(callback) {
    return (filepath, stats) => callback(path().normalize(filepath), stats);
  }

  static recReaddir(
    dir,
    dirCallback,
    fileCallback,
    endCallback,
    errorCallback,
    ignored
  ) {
    (0, _walker().default)(dir)
      .filterDir(
        currentDir => !ignored || !(0, _anymatch().default)(ignored, currentDir)
      )
      .on('dir', FSEventsWatcher.normalizeProxy(dirCallback))
      .on('file', FSEventsWatcher.normalizeProxy(fileCallback))
      .on('error', errorCallback)
      .on('end', () => {
        endCallback();
      });
  }

  constructor(dir, opts) {
    if (!fsevents) {
      throw new Error(
        '`fsevents` unavailable (this watcher can only be used on Darwin)'
      );
    }

    super();

    _defineProperty(this, 'root', void 0);

    _defineProperty(this, 'ignored', void 0);

    _defineProperty(this, 'glob', void 0);

    _defineProperty(this, 'dot', void 0);

    _defineProperty(this, 'hasIgnore', void 0);

    _defineProperty(this, 'doIgnore', void 0);

    _defineProperty(this, 'fsEventsWatchStopper', void 0);

    _defineProperty(this, '_tracked', void 0);

    this.dot = opts.dot || false;
    this.ignored = opts.ignored;
    this.glob = Array.isArray(opts.glob) ? opts.glob : [opts.glob];
    this.hasIgnore =
      Boolean(opts.ignored) && !(Array.isArray(opts) && opts.length > 0);
    this.doIgnore = opts.ignored
      ? (0, _anymatch().default)(opts.ignored)
      : () => false;
    this.root = path().resolve(dir);
    this.fsEventsWatchStopper = fsevents.watch(
      this.root,
      this.handleEvent.bind(this)
    );
    this._tracked = new Set();
    FSEventsWatcher.recReaddir(
      this.root,
      filepath => {
        this._tracked.add(filepath);
      },
      filepath => {
        this._tracked.add(filepath);
      },
      this.emit.bind(this, 'ready'),
      this.emit.bind(this, 'error'),
      this.ignored
    );
  }
  /**
   * End watching.
   */

  close(callback) {
    this.fsEventsWatchStopper().then(() => {
      this.removeAllListeners();

      if (typeof callback === 'function') {
        process.nextTick(callback.bind(null, null, true));
      }
    });
  }

  isFileIncluded(relativePath) {
    if (this.doIgnore(relativePath)) {
      return false;
    }

    return this.glob.length
      ? (0, _micromatch().default)([relativePath], this.glob, {
          dot: this.dot
        }).length > 0
      : this.dot ||
          (0, _micromatch().default)([relativePath], '**/*').length > 0;
  }

  handleEvent(filepath) {
    const relativePath = path().relative(this.root, filepath);

    if (!this.isFileIncluded(relativePath)) {
      return;
    }

    fs().lstat(filepath, (error, stat) => {
      if (error && error.code !== 'ENOENT') {
        this.emit('error', error);
        return;
      }

      if (error) {
        // Ignore files that aren't tracked and don't exist.
        if (!this._tracked.has(filepath)) {
          return;
        }

        this._emit(DELETE_EVENT, relativePath);

        this._tracked.delete(filepath);

        return;
      }

      if (this._tracked.has(filepath)) {
        this._emit(CHANGE_EVENT, relativePath, stat);
      } else {
        this._tracked.add(filepath);

        this._emit(ADD_EVENT, relativePath, stat);
      }
    });
  }
  /**
   * Emit events.
   */

  _emit(type, file, stat) {
    this.emit(type, file, this.root, stat);
    this.emit(ALL_EVENT, type, file, this.root, stat);
  }
}

module.exports = FSEventsWatcher;
