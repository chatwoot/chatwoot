import { defineComponent, openBlock, createElementBlock, normalizeClass, renderSlot, createElementVNode, createCommentVNode } from 'vue';

function _toConsumableArray(arr) {
  return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
}

function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}

function _unsupportedIterableToArray(o, minLen) {
  if (!o) return;
  if (typeof o === "string") return _arrayLikeToArray(o, minLen);
  var n = Object.prototype.toString.call(o).slice(8, -1);
  if (n === "Object" && o.constructor) n = o.constructor.name;
  if (n === "Map" || n === "Set") return Array.from(o);
  if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
}

function _iterableToArray(iter) {
  if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
}

function _arrayWithoutHoles(arr) {
  if (Array.isArray(arr)) return _arrayLikeToArray(arr);
}

function _arrayLikeToArray(arr, len) {
  if (len == null || len > arr.length) len = arr.length;

  for (var i = 0, arr2 = new Array(len); i < len; i++) {
    arr2[i] = arr[i];
  }

  return arr2;
}

function _ownKeys(object, enumerableOnly) {
  var keys = Object.keys(object);

  if (Object.getOwnPropertySymbols) {
    var symbols = Object.getOwnPropertySymbols(object);
    enumerableOnly && (symbols = symbols.filter(function (sym) {
      return Object.getOwnPropertyDescriptor(object, sym).enumerable;
    })), keys.push.apply(keys, symbols);
  }

  return keys;
}

function _objectSpread(target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = null != arguments[i] ? arguments[i] : {};
    i % 2 ? _ownKeys(Object(source), !0).forEach(function (key) {
      _defineProperty2(target, key, source[key]);
    }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : _ownKeys(Object(source)).forEach(function (key) {
      Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
    });
  }

  return target;
}

function _defineProperty2(obj, key, value) {
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

function _typeof(obj) {
  "@babel/helpers - typeof";

  return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) {
    return typeof obj;
  } : function (obj) {
    return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
  }, _typeof(obj);
}

function ownKeys(object, enumerableOnly) {
  var keys = Object.keys(object);

  if (Object.getOwnPropertySymbols) {
    var symbols = Object.getOwnPropertySymbols(object);
    enumerableOnly && (symbols = symbols.filter(function (sym) {
      return Object.getOwnPropertyDescriptor(object, sym).enumerable;
    })), keys.push.apply(keys, symbols);
  }

  return keys;
}

function _objectSpread2(target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = null != arguments[i] ? arguments[i] : {};
    i % 2 ? ownKeys(Object(source), !0).forEach(function (key) {
      _defineProperty(target, key, source[key]);
    }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) {
      Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
    });
  }

  return target;
}

function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, descriptor.key, descriptor);
  }
}

function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties(Constructor, staticProps);
  Object.defineProperty(Constructor, "prototype", {
    writable: false
  });
  return Constructor;
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
/**
 * Creates a XHR request
 *
 * @param {Object} options
 */


var createRequest = function createRequest(options) {
  var xhr = new XMLHttpRequest();
  xhr.open(options.method || 'GET', options.url);
  xhr.responseType = 'json';

  if (options.headers) {
    Object.keys(options.headers).forEach(function (key) {
      xhr.setRequestHeader(key, options.headers[key]);
    });
  }

  return xhr;
};
/**
 * Sends a XHR request with certain body
 *
 * @param {XMLHttpRequest} xhr
 * @param {Object} body
 */


var sendRequest = function sendRequest(xhr, body) {
  return new Promise(function (resolve, reject) {
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        var response;

        try {
          response = JSON.parse(xhr.response);
        } catch (err) {
          response = xhr.response;
        }

        resolve(response);
      } else {
        reject(xhr.response);
      }
    };

    xhr.onerror = function () {
      return reject(xhr.response);
    };

    xhr.send(JSON.stringify(body));
  });
};
/**
 * Sends a XHR request with certain form data
 *
 * @param {XMLHttpRequest} xhr
 * @param {Object} data
 */


var sendFormRequest = function sendFormRequest(xhr, data) {
  var body = new FormData();

  for (var name in data) {
    body.append(name, data[name]);
  }

  return new Promise(function (resolve, reject) {
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        var response;

        try {
          response = JSON.parse(xhr.response);
        } catch (err) {
          response = xhr.response;
        }

        resolve(response);
      } else {
        reject(xhr.response);
      }
    };

    xhr.onerror = function () {
      return reject(xhr.response);
    };

    xhr.send(body);
  });
};
/**
 * Creates and sends XHR request
 *
 * @param {Object} options
 *
 * @returns Promise
 */


function request(options) {
  var xhr = createRequest(options);
  return sendRequest(xhr, options.body);
}

var ChunkUploadHandler = /*#__PURE__*/function () {
  /**
   * Constructor
   *
   * @param {File} file
   * @param {Object} options
   */
  function ChunkUploadHandler(file, options) {
    _classCallCheck(this, ChunkUploadHandler);

    this.file = file;
    this.options = options;
    this.chunks = [];
    this.sessionId = null;
    this.chunkSize = null;
    this.speedInterval = null;
  }
  /**
   * Gets the max retries from options
   */


  _createClass(ChunkUploadHandler, [{
    key: "maxRetries",
    get: function get() {
      return parseInt(this.options.maxRetries, 10);
    }
    /**
     * Gets the max number of active chunks being uploaded at once from options
     */

  }, {
    key: "maxActiveChunks",
    get: function get() {
      return parseInt(this.options.maxActive, 10);
    }
    /**
     * Gets the file type
     */

  }, {
    key: "fileType",
    get: function get() {
      return this.file.type;
    }
    /**
     * Gets the file size
     */

  }, {
    key: "fileSize",
    get: function get() {
      return this.file.size;
    }
    /**
     * Gets the file name
     */

  }, {
    key: "fileName",
    get: function get() {
      return this.file.name;
    }
    /**
     * Gets action (url) to upload the file
     */

  }, {
    key: "action",
    get: function get() {
      return this.options.action || null;
    }
    /**
     * Gets the body to be merged when sending the request in start phase
     */

  }, {
    key: "startBody",
    get: function get() {
      return this.options.startBody || {};
    }
    /**
     * Gets the body to be merged when sending the request in upload phase
     */

  }, {
    key: "uploadBody",
    get: function get() {
      return this.options.uploadBody || {};
    }
    /**
     * Gets the body to be merged when sending the request in finish phase
     */

  }, {
    key: "finishBody",
    get: function get() {
      return this.options.finishBody || {};
    }
    /**
     * Gets the headers of the requests from options
     */

  }, {
    key: "headers",
    get: function get() {
      return this.options.headers || {};
    }
    /**
     * Whether it's ready to upload files or not
     */

  }, {
    key: "readyToUpload",
    get: function get() {
      return !!this.chunks;
    }
    /**
     * Gets the progress of the chunk upload
     * - Gets all the completed chunks
     * - Gets the progress of all the chunks that are being uploaded
     */

  }, {
    key: "progress",
    get: function get() {
      var _this = this;

      var completedProgress = this.chunksUploaded.length / this.chunks.length * 100;
      var uploadingProgress = this.chunksUploading.reduce(function (progress, chunk) {
        return progress + (chunk.progress | 0) / _this.chunks.length;
      }, 0);
      return Math.min(completedProgress + uploadingProgress, 100);
    }
    /**
     * Gets all the chunks that are pending to be uploaded
     */

  }, {
    key: "chunksToUpload",
    get: function get() {
      return this.chunks.filter(function (chunk) {
        return !chunk.active && !chunk.uploaded;
      });
    }
    /**
     * Whether there are chunks to upload or not
     */

  }, {
    key: "hasChunksToUpload",
    get: function get() {
      return this.chunksToUpload.length > 0;
    }
    /**
     * Gets all the chunks that are uploading
     */

  }, {
    key: "chunksUploading",
    get: function get() {
      return this.chunks.filter(function (chunk) {
        return !!chunk.xhr && !!chunk.active;
      });
    }
    /**
     * Gets all the chunks that have finished uploading
     */

  }, {
    key: "chunksUploaded",
    get: function get() {
      return this.chunks.filter(function (chunk) {
        return !!chunk.uploaded;
      });
    }
    /**
     * Creates all the chunks in the initial state
     */

  }, {
    key: "createChunks",
    value: function createChunks() {
      this.chunks = [];
      var start = 0;
      var end = this.chunkSize;

      while (start < this.fileSize) {
        this.chunks.push({
          blob: this.file.file.slice(start, end),
          startOffset: start,
          active: false,
          retries: this.maxRetries
        });
        start = end;
        end = start + this.chunkSize;
      }
    }
    /**
     * Updates the progress of the file with the handler's progress
     */

  }, {
    key: "updateFileProgress",
    value: function updateFileProgress() {
      this.file.progress = this.progress;
    }
    /**
     * Paues the upload process
     * - Stops all active requests
     * - Sets the file not active
     */

  }, {
    key: "pause",
    value: function pause() {
      this.file.active = false;
      this.stopChunks();
    }
    /**
     * Stops all the current chunks
     */

  }, {
    key: "stopChunks",
    value: function stopChunks() {
      this.chunksUploading.forEach(function (chunk) {
        chunk.xhr.abort();
        chunk.active = false;
      });
      this.stopSpeedCalc();
    }
    /**
     * Resumes the file upload
     * - Sets the file active
     * - Starts the following chunks
     */

  }, {
    key: "resume",
    value: function resume() {
      this.file.active = true;
      this.startChunking();
    }
    /**
     * Starts the file upload
     *
     * @returns Promise
     * - resolve  The file was uploaded
     * - reject   The file upload failed
     */

  }, {
    key: "upload",
    value: function upload() {
      var _this2 = this;

      this.promise = new Promise(function (resolve, reject) {
        _this2.resolve = resolve;
        _this2.reject = reject;
      });
      this.start();
      return this.promise;
    }
    /**
     * Start phase
     * Sends a request to the backend to initialise the chunks
     */

  }, {
    key: "start",
    value: function start() {
      var _this3 = this;

      request({
        method: 'POST',
        headers: _objectSpread2(_objectSpread2({}, this.headers), {}, {
          'Content-Type': 'application/json'
        }),
        url: this.action,
        body: Object.assign(this.startBody, {
          phase: 'start',
          mime_type: this.fileType,
          size: this.fileSize,
          name: this.fileName
        })
      }).then(function (res) {
        if (res.status !== 'success') {
          _this3.file.response = res;
          return _this3.reject('server');
        }

        _this3.sessionId = res.data.session_id;
        _this3.chunkSize = res.data.end_offset;

        _this3.createChunks();

        _this3.startChunking();
      }).catch(function (res) {
        _this3.file.response = res;

        _this3.reject('server');
      });
    }
    /**
     * Starts to upload chunks
     */

  }, {
    key: "startChunking",
    value: function startChunking() {
      for (var i = 0; i < this.maxActiveChunks; i++) {
        this.uploadNextChunk();
      }

      this.startSpeedCalc();
    }
    /**
     * Uploads the next chunk
     * - Won't do anything if the process is paused
     * - Will start finish phase if there are no more chunks to upload
     */

  }, {
    key: "uploadNextChunk",
    value: function uploadNextChunk() {
      if (this.file.active) {
        if (this.hasChunksToUpload) {
          return this.uploadChunk(this.chunksToUpload[0]);
        }

        if (this.chunksUploading.length === 0) {
          return this.finish();
        }
      }
    }
    /**
     * Uploads a chunk
     * - Sends the chunk to the backend
     * - Sets the chunk as uploaded if everything went well
     * - Decreases the number of retries if anything went wrong
     * - Fails if there are no more retries
     *
     * @param {Object} chunk
     */

  }, {
    key: "uploadChunk",
    value: function uploadChunk(chunk) {
      var _this4 = this;

      chunk.progress = 0;
      chunk.active = true;
      this.updateFileProgress();
      chunk.xhr = createRequest({
        method: 'POST',
        headers: this.headers,
        url: this.action
      });
      chunk.xhr.upload.addEventListener('progress', function (evt) {
        if (evt.lengthComputable) {
          chunk.progress = Math.round(evt.loaded / evt.total * 100);
        }
      }, false);
      sendFormRequest(chunk.xhr, Object.assign(this.uploadBody, {
        phase: 'upload',
        session_id: this.sessionId,
        start_offset: chunk.startOffset,
        chunk: chunk.blob
      })).then(function (res) {
        chunk.active = false;

        if (res.status === 'success') {
          chunk.uploaded = true;
        } else {
          if (chunk.retries-- <= 0) {
            _this4.stopChunks();

            return _this4.reject('upload');
          }
        }

        _this4.uploadNextChunk();
      }).catch(function () {
        chunk.active = false;

        if (chunk.retries-- <= 0) {
          _this4.stopChunks();

          return _this4.reject('upload');
        }

        _this4.uploadNextChunk();
      });
    }
    /**
     * Finish phase
     * Sends a request to the backend to finish the process
     */

  }, {
    key: "finish",
    value: function finish() {
      var _this5 = this;

      this.updateFileProgress();
      this.stopSpeedCalc();
      request({
        method: 'POST',
        headers: _objectSpread2(_objectSpread2({}, this.headers), {}, {
          'Content-Type': 'application/json'
        }),
        url: this.action,
        body: Object.assign(this.finishBody, {
          phase: 'finish',
          session_id: this.sessionId
        })
      }).then(function (res) {
        _this5.file.response = res;

        if (res.status !== 'success') {
          return _this5.reject('server');
        }

        _this5.resolve(res);
      }).catch(function (res) {
        _this5.file.response = res;

        _this5.reject('server');
      });
    }
    /**
     * Sets an interval to calculate and
     * set upload speed every 3 seconds
     */

  }, {
    key: "startSpeedCalc",
    value: function startSpeedCalc() {
      var _this6 = this;

      this.file.speed = 0;
      var lastUploadedBytes = 0;

      if (!this.speedInterval) {
        this.speedInterval = window.setInterval(function () {
          var uploadedBytes = _this6.progress / 100 * _this6.fileSize;
          _this6.file.speed = uploadedBytes - lastUploadedBytes;
          lastUploadedBytes = uploadedBytes;
        }, 1000);
      }
    }
    /**
     * Removes the upload speed interval
     */

  }, {
    key: "stopSpeedCalc",
    value: function stopSpeedCalc() {
      this.speedInterval && window.clearInterval(this.speedInterval);
      this.speedInterval = null;
      this.file.speed = 0;
    }
  }]);

  return ChunkUploadHandler;
}();

var CHUNK_DEFAULT_OPTIONS = {
  headers: {},
  action: '',
  minSize: 1048576,
  maxActive: 3,
  maxRetries: 5,
  handler: ChunkUploadHandler
};
var script = defineComponent({
  compatConfig: {
    MODE: 3
  },
  props: {
    inputId: {
      type: String
    },
    name: {
      type: String,
      default: 'file'
    },
    accept: {
      type: String
    },
    capture: {},
    disabled: {
      default: false
    },
    multiple: {
      type: Boolean,
      default: false
    },
    maximum: {
      type: Number
    },
    addIndex: {
      type: [Boolean, Number]
    },
    directory: {
      type: Boolean
    },
    createDirectory: {
      type: Boolean,
      default: false
    },
    postAction: {
      type: String
    },
    putAction: {
      type: String
    },
    customAction: {
      type: Function
    },
    headers: {
      type: Object,
      default: function _default() {
        return {};
      }
    },
    data: {
      type: Object,
      default: function _default() {
        return {};
      }
    },
    timeout: {
      type: Number,
      default: 0
    },
    drop: {
      type: [Boolean, String, HTMLElement],
      default: function _default() {
        return false;
      }
    },
    dropDirectory: {
      type: Boolean,
      default: true
    },
    size: {
      type: Number,
      default: 0
    },
    extensions: {
      type: [RegExp, String, Array],
      default: function _default() {
        return [];
      }
    },
    modelValue: {
      type: Array,
      default: function _default() {
        return [];
      }
    },
    thread: {
      type: Number,
      default: 1
    },
    // Chunk upload enabled
    chunkEnabled: {
      type: Boolean,
      default: false
    },
    // Chunk upload properties
    chunk: {
      type: Object,
      default: function _default() {
        return CHUNK_DEFAULT_OPTIONS;
      }
    }
  },
  emits: ['update:modelValue', 'input-filter', 'input-file'],
  data: function data() {
    return {
      files: this.modelValue,
      features: {
        html5: true,
        directory: false,
        drop: false
      },
      active: false,
      dropActive: false,
      dropElementActive: false,
      uploading: 0,
      destroy: false,
      maps: {},
      dropElement: null,
      dropTimeout: null,
      reload: false
    };
  },

  /**
   * mounted
   * @return {[type]} [description]
   */
  mounted: function mounted() {
    var _this7 = this;

    var input = document.createElement('input');
    input.type = 'file';
    input.multiple = true; // html5 特征

    if (window.FormData && input.files) {
      // 上传目录特征
      // @ts-ignore
      if (typeof input.webkitdirectory === 'boolean' || typeof input.directory === 'boolean') {
        this.features.directory = true;
      } // 拖拽特征. 要兼容 relatedTarget


      if (this.features.html5 && typeof input.ondrop !== 'undefined' && this.isRelatedTargetSupported()) {
        this.features.drop = true;
      }
    } else {
      this.features.html5 = false;
    } // files 定位缓存


    this.maps = {};

    if (this.files) {
      for (var i = 0; i < this.files.length; i++) {
        var file = this.files[i];
        this.maps[file.id] = file;
      }
    } // @ts-ignore


    this.$nextTick(function () {
      // 更新下父级
      if (_this7.$parent) {
        _this7.$parent.$forceUpdate(); // 拖拽渲染


        _this7.$parent.$nextTick(function () {
          _this7.watchDrop(_this7.drop);
        });
      } else {
        // 拖拽渲染
        _this7.watchDrop(_this7.drop);
      }
    });
  },

  /**
   * beforeUnmount
   * @return {[type]} [description]
   */
  beforeUnmount: function beforeUnmount() {
    // 已销毁
    this.destroy = true; // 设置成不激活

    this.active = false; // 销毁拖拽事件

    this.watchDrop(false); // 销毁不激活

    this.watchActive(false);
  },
  computed: {
    /**
     * uploading 正在上传的线程
     * @return {[type]} [description]
     */

    /**
     * uploaded 文件列表是否全部已上传
     * @return {[type]} [description]
     */
    uploaded: function uploaded() {
      var file;

      for (var i = 0; i < this.files.length; i++) {
        file = this.files[i];

        if (file.fileObject && !file.error && !file.success) {
          return false;
        }
      }

      return true;
    },
    chunkOptions: function chunkOptions() {
      return Object.assign(CHUNK_DEFAULT_OPTIONS, this.chunk);
    },
    className: function className() {
      return ['file-uploads', this.features.html5 ? 'file-uploads-html5' : 'file-uploads-html4', this.features.directory && this.directory ? 'file-uploads-directory' : undefined, this.features.drop && this.drop ? 'file-uploads-drop' : undefined, this.disabled ? 'file-uploads-disabled' : undefined];
    },
    forId: function forId() {
      return this.inputId || this.name;
    },
    iMaximum: function iMaximum() {
      if (this.maximum === undefined) {
        return this.multiple ? 0 : 1;
      }

      return this.maximum;
    },
    iExtensions: function iExtensions() {
      if (!this.extensions) {
        return;
      }

      if (this.extensions instanceof RegExp) {
        return this.extensions;
      }

      if (!this.extensions.length) {
        return;
      }

      var exts = [];

      if (typeof this.extensions === 'string') {
        exts = this.extensions.split(',');
      } else {
        exts = this.extensions;
      }

      exts = exts.map(function (value) {
        return value.trim();
      }).filter(function (value) {
        return value;
      });
      return new RegExp('\\.(' + exts.join('|').replace(/\./g, '\\.') + ')$', 'i');
    },
    iDirectory: function iDirectory() {
      if (this.directory && this.features.directory) {
        return true;
      }

      return undefined;
    }
  },
  watch: {
    active: function active(_active) {
      this.watchActive(_active);
    },
    dropActive: function dropActive(value) {
      this.watchDropActive(value);

      if (this.$parent) {
        this.$parent.$forceUpdate();
      }
    },
    drop: function drop(value) {
      this.watchDrop(value);
    },
    modelValue: function modelValue(files) {
      if (this.files === files) {
        return;
      }

      this.files = files;
      var oldMaps = this.maps; // 重写 maps 缓存

      this.maps = {};

      for (var i = 0; i < this.files.length; i++) {
        var file = this.files[i];
        this.maps[file.id] = file;
      } // add, update


      for (var key in this.maps) {
        var newFile = this.maps[key];
        var oldFile = oldMaps[key];

        if (newFile !== oldFile) {
          this.emitFile(newFile, oldFile);
        }
      } // delete


      for (var _key in oldMaps) {
        if (!this.maps[_key]) {
          this.emitFile(undefined, oldMaps[_key]);
        }
      }
    }
  },
  methods: {
    newId: function newId() {
      return Math.random().toString(36).substr(2);
    },
    // 清空
    clear: function clear() {
      if (this.files.length) {
        var files = this.files;
        this.files = []; // 定位

        this.maps = {}; // 事件

        this.emitInput();

        for (var i = 0; i < files.length; i++) {
          this.emitFile(undefined, files[i]);
        }
      }

      return true;
    },
    // 选择
    get: function get(id) {
      if (!id) {
        return false;
      }

      if (_typeof(id) === 'object') {
        return this.maps[id.id || ''] || false;
      }

      return this.maps[id] || false;
    },
    // 添加
    add: function add(_files, index) {
      // 不是数组整理成数组
      var files;

      if (_files instanceof Array) {
        files = _files;
      } else {
        files = [_files];
      }

      if (index === undefined) {
        // eslint-disable-next-line
        index = this.addIndex;
      } // 遍历规范对象


      var addFiles = [];

      for (var i = 0; i < files.length; i++) {
        var file = files[i];

        if (this.features.html5 && file instanceof Blob) {
          file = {
            id: '',
            file: file,
            size: file.size,
            // @ts-ignore
            name: file.webkitRelativePath || file.relativePath || file.name || 'unknown',
            type: file.type
          };
        }

        file = file;
        var fileObject = false;
        if (file.fileObject === false) ;else if (file.fileObject) {
          fileObject = true;
        } else if (typeof Element !== 'undefined' && file.el instanceof HTMLInputElement) {
          fileObject = true;
        } else if (typeof Blob !== 'undefined' && file.file instanceof Blob) {
          fileObject = true;
        }

        if (fileObject) {
          file = _objectSpread(_objectSpread({
            fileObject: true,
            size: -1,
            name: 'Filename',
            type: '',
            active: false,
            error: '',
            success: false,
            putAction: this.putAction,
            postAction: this.postAction,
            timeout: this.timeout
          }, file), {}, {
            response: {},
            progress: '0.00',
            speed: 0 // 只读
            // file: undefined,
            // xhr: undefined,
            // el: undefined,
            // iframe: undefined,

          });
          file.data = _objectSpread(_objectSpread({}, this.data), file.data ? file.data : {});
          file.headers = _objectSpread(_objectSpread({}, this.headers), file.headers ? file.headers : {});
        } // 必须包含 id


        if (!file.id) {
          file.id = this.newId();
        }

        if (this.emitFilter(file, undefined)) {
          continue;
        } // 最大数量限制


        if (this.iMaximum > 1 && addFiles.length + this.files.length >= this.iMaximum) {
          break;
        }

        addFiles.push(file); // 最大数量限制

        if (this.iMaximum === 1) {
          break;
        }
      } // 没有文件


      if (!addFiles.length) {
        return;
      } // 如果是 1 清空


      if (this.iMaximum === 1) {
        this.clear();
      } // 添加进去 files


      var newFiles;

      if (index === true || index === 0) {
        newFiles = addFiles.concat(this.files);
      } else if (index) {
        var _newFiles;

        newFiles = this.files.concat([]);

        (_newFiles = newFiles).splice.apply(_newFiles, [index, 0].concat(_toConsumableArray(addFiles)));
      } else {
        newFiles = this.files.concat(addFiles);
      }

      this.files = newFiles; // 读取代理后的数据

      var index2 = 0;

      if (index === true || index === 0) {
        index2 = 0;
      } else if (index) {
        if (index >= 0) {
          if (index + addFiles.length > this.files.length) {
            index2 = this.files.length - addFiles.length;
          } else {
            index2 = index;
          }
        } else {
          index2 = this.files.length - addFiles.length + index;

          if (index2 < 0) {
            index2 = 0;
          }
        }
      } else {
        index2 = this.files.length - addFiles.length;
      }

      addFiles = this.files.slice(index2, index2 + addFiles.length); // 定位

      for (var _i = 0; _i < addFiles.length; _i++) {
        var _file = addFiles[_i];
        this.maps[_file.id] = _file;
      } // 事件


      this.emitInput();

      for (var _i2 = 0; _i2 < addFiles.length; _i2++) {
        this.emitFile(addFiles[_i2], undefined);
      }

      return _files instanceof Array ? addFiles : addFiles[0];
    },
    // 添加表单文件
    addInputFile: function addInputFile(el) {
      var _this8 = this;

      var files = [];
      this.iMaximum; // @ts-ignore

      var entrys = el.webkitEntries || el.entries || undefined;

      if (entrys !== null && entrys !== void 0 && entrys.length) {
        return this.getFileSystemEntry(entrys).then(function (files) {
          return _this8.add(files);
        });
      }

      if (el.files) {
        for (var i = 0; i < el.files.length; i++) {
          var file = el.files[i];
          files.push({
            id: '',
            size: file.size,
            // @ts-ignore
            name: file.webkitRelativePath || file.relativePath || file.name,
            type: file.type,
            file: file
          });
        }
      } else {
        var names = el.value.replace(/\\/g, '/').split('/');

        if (!names || !names.length) {
          names = [el.value];
        } // @ts-ignore


        delete el.__vuex__;
        files.push({
          id: '',
          name: names[names.length - 1],
          el: el
        });
      }

      return Promise.resolve(this.add(files));
    },
    // 添加 DataTransfer
    addDataTransfer: function addDataTransfer(dataTransfer) {
      var _dataTransfer$items,
          _this9 = this; // dataTransfer.items 支持


      if (dataTransfer !== null && dataTransfer !== void 0 && (_dataTransfer$items = dataTransfer.items) !== null && _dataTransfer$items !== void 0 && _dataTransfer$items.length) {
        var entrys = []; // 遍历出所有 dataTransferVueUploadItem

        for (var i = 0; i < dataTransfer.items.length; i++) {
          var dataTransferTtem = dataTransfer.items[i];
          var entry = void 0; // @ts-ignore

          if (dataTransferTtem.getAsEntry) {
            // @ts-ignore
            entry = dataTransferTtem.getAsEntry() || dataTransferTtem.getAsFile();
          } else if (dataTransferTtem.webkitGetAsEntry) {
            entry = dataTransferTtem.webkitGetAsEntry() || dataTransferTtem.getAsFile();
          } else {
            entry = dataTransferTtem.getAsFile();
          }

          if (entry) {
            entrys.push(entry);
          }
        }

        return this.getFileSystemEntry(entrys).then(function (files) {
          return _this9.add(files);
        });
      } // dataTransfer.files 支持


      var maximumValue = this.iMaximum;
      var files = [];

      if (dataTransfer.files.length) {
        for (var _i3 = 0; _i3 < dataTransfer.files.length; _i3++) {
          files.push(dataTransfer.files[_i3]);

          if (maximumValue > 0 && files.length >= maximumValue) {
            break;
          }
        }

        return Promise.resolve(this.add(files));
      }

      return Promise.resolve([]);
    },
    // 获得 entrys    
    getFileSystemEntry: function getFileSystemEntry(entry) {
      var _this10 = this;

      var path = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : ''; // getFileSystemEntry(entry: any, path = ''): Promise<VueUploadItem[]> {

      return new Promise(function (resolve) {
        var maximumValue = _this10.iMaximum;

        if (!entry) {
          resolve([]);
          return;
        }

        if (entry instanceof Array) {
          // 多个
          var uploadFiles = [];

          var forEach = function forEach(i) {
            var v = entry[i];

            if (!v || maximumValue > 0 && uploadFiles.length >= maximumValue) {
              return resolve(uploadFiles);
            }

            _this10.getFileSystemEntry(v, path).then(function (results) {
              uploadFiles.push.apply(uploadFiles, _toConsumableArray(results));
              forEach(i + 1);
            });
          };

          forEach(0);
          return;
        }

        if (entry instanceof Blob) {
          resolve([{
            id: '',
            size: entry.size,
            // @ts-ignore
            name: path + entry.name,
            type: entry.type,
            file: entry
          }]);
          return;
        }

        if (entry.isFile) {
          var fileEntry = entry;
          fileEntry.file(function (file) {
            resolve([{
              id: '',
              size: file.size,
              name: path + file.name,
              type: file.type,
              file: file
            }]);
          });
          return;
        }

        if (entry.isDirectory && _this10.dropDirectory) {
          var directoryEntry = entry;
          var _uploadFiles = []; // 目录也要添加到文件列表

          if (_this10.createDirectory) {
            _uploadFiles.push({
              id: '',
              name: path + directoryEntry.name,
              size: 0,
              type: 'text/directory',
              file: new File([], path + directoryEntry.name, {
                type: 'text/directory'
              })
            });
          }

          var dirReader = directoryEntry.createReader();

          var readEntries = function readEntries() {
            dirReader.readEntries(function (entries) {
              var forEach = function forEach(i) {
                if (!entries[i] && i === 0 || maximumValue > 0 && _uploadFiles.length >= maximumValue) {
                  return resolve(_uploadFiles);
                }

                if (!entries[i]) {
                  return readEntries();
                }

                _this10.getFileSystemEntry(entries[i], path + directoryEntry.name + '/').then(function (results) {
                  _uploadFiles.push.apply(_uploadFiles, _toConsumableArray(results));

                  forEach(i + 1);
                });
              };

              forEach(0);
            });
          };

          readEntries();
          return;
        }

        resolve([]);
      });
    },
    // 替换
    replace: function replace(id1, id2) {
      var file1 = this.get(id1);
      var file2 = this.get(id2);

      if (!file1 || !file2 || file1 === file2) {
        return false;
      }

      var files = this.files.concat([]);
      var index1 = files.indexOf(file1);
      var index2 = files.indexOf(file2);

      if (index1 === -1 || index2 === -1) {
        return false;
      }

      files[index1] = file2;
      files[index2] = file1;
      this.files = files;
      this.emitInput();
      return true;
    },
    // 移除
    remove: function remove(id) {
      var file = this.get(id);

      if (file) {
        if (this.emitFilter(undefined, file)) {
          return false;
        }

        var files = this.files.concat([]);
        var index = files.indexOf(file);

        if (index === -1) {
          console.error('remove', file);
          return false;
        }

        files.splice(index, 1);
        this.files = files; // 定位

        delete this.maps[file.id]; // 事件

        this.emitInput();
        this.emitFile(undefined, file);
      }

      return file;
    },
    // 更新
    update: function update(id, data) {
      var file = this.get(id);

      if (file) {
        var newFile = _objectSpread(_objectSpread({}, file), data); // 停用必须加上错误


        if (file.fileObject && file.active && !newFile.active && !newFile.error && !newFile.success) {
          newFile.error = 'abort';
        }

        if (this.emitFilter(newFile, file)) {
          return false;
        }

        var files = this.files.concat([]);
        var index = files.indexOf(file);

        if (index === -1) {
          console.error('update', file);
          return false;
        }

        files.splice(index, 1, newFile);
        this.files = files;
        newFile = this.files[index]; // 删除  旧定位 写入 新定位 （已便支持修改id)

        delete this.maps[file.id];
        this.maps[newFile.id] = newFile; // 事件

        this.emitInput();
        this.emitFile(newFile, file);
        return newFile;
      }

      return false;
    },
    // 预处理 事件 过滤器
    emitFilter: function emitFilter(newFile, oldFile) {
      var isPrevent = false;
      this.$emit('input-filter', newFile, oldFile, function () {
        var prevent = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;
        isPrevent = prevent;
        return isPrevent;
      });
      return isPrevent;
    },
    // 处理后 事件 分发
    emitFile: function emitFile(newFile, oldFile) {
      var _newFile,
          _this11 = this;

      this.$emit('input-file', newFile, oldFile);

      if ((_newFile = newFile) !== null && _newFile !== void 0 && _newFile.fileObject && newFile.active && (!oldFile || !oldFile.active)) {
        this.uploading++; // 激活
        // @ts-ignore

        this.$nextTick(function () {
          setTimeout(function () {
            newFile && _this11.upload(newFile).then(function () {
              var _newFile2;

              if (newFile) {
                // eslint-disable-next-line
                newFile = _this11.get(newFile) || undefined;
              }

              if ((_newFile2 = newFile) !== null && _newFile2 !== void 0 && _newFile2.fileObject) {
                _this11.update(newFile, {
                  active: false,
                  success: !newFile.error
                });
              }
            }).catch(function (e) {
              newFile && _this11.update(newFile, {
                active: false,
                success: false,
                error: e.code || e.error || e.message || e
              });
            });
          }, Math.ceil(Math.random() * 50 + 50));
        });
      } else if ((!newFile || !newFile.fileObject || !newFile.active) && oldFile && oldFile.fileObject && oldFile.active) {
        // 停止
        this.uploading--;
      } // 自动延续激活
      // @ts-ignore


      if (this.active && (Boolean(newFile) !== Boolean(oldFile) || newFile.active !== oldFile.active)) {
        this.watchActive(true);
      }
    },
    emitInput: function emitInput() {
      this.$emit('update:modelValue', this.files);
    },
    // 上传
    upload: function upload(id) {
      var file = this.get(id); // 被删除

      if (!file) {
        return Promise.reject(new Error('not_exists'));
      } // 不是文件对象


      if (!file.fileObject) {
        return Promise.reject(new Error('file_object'));
      } // 有错误直接响应


      if (file.error) {
        if (file.error instanceof Error) {
          return Promise.reject(file.error);
        }

        return Promise.reject(new Error(file.error));
      } // 已完成直接响应


      if (file.success) {
        return Promise.resolve(file);
      } // 后缀


      if (file.name && this.iExtensions && file.type !== "text/directory") {
        if (file.name.search(this.iExtensions) === -1) {
          return Promise.reject(new Error('extension'));
        }
      } // 大小


      if (this.size > 0 && file.size !== undefined && file.size >= 0 && file.size > this.size && file.type !== "text/directory") {
        return Promise.reject(new Error('size'));
      }

      if (this.customAction) {
        return this.customAction(file, this);
      }

      if (this.features.html5) {
        if (this.shouldUseChunkUpload(file)) {
          return this.uploadChunk(file);
        }

        if (file.putAction) {
          return this.uploadPut(file);
        }

        if (file.postAction) {
          return this.uploadHtml5(file);
        }
      }

      if (file.postAction) {
        return this.uploadHtml4(file);
      }

      return Promise.reject(new Error('No action configured'));
    },

    /**
     * Whether this file should be uploaded using chunk upload or not
     *
     * @param Object file
     */
    shouldUseChunkUpload: function shouldUseChunkUpload(file) {
      return this.chunkEnabled && !!this.chunkOptions.handler && file.size && file.size > this.chunkOptions.minSize;
    },

    /**
     * Upload a file using Chunk method
     *
     * @param File file
     */
    uploadChunk: function uploadChunk(file) {
      var HandlerClass = this.chunkOptions.handler;
      file.chunk = new HandlerClass(file, this.chunkOptions);
      return file.chunk.upload().then(function (res) {
        return file;
      });
    },
    uploadPut: function uploadPut(file) {
      var querys = [];
      var value;

      for (var key in file.data) {
        value = file.data[key];

        if (value !== null && value !== undefined) {
          querys.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
        }
      }

      var putAction = file.putAction || '';
      var queryString = querys.length ? (putAction.indexOf('?') === -1 ? '?' : '&') + querys.join('&') : '';
      var xhr = new XMLHttpRequest();
      xhr.open('PUT', putAction + queryString);
      return this.uploadXhr(xhr, file, file.file);
    },
    uploadHtml5: function uploadHtml5(file) {
      var form = new window.FormData();
      var value;

      for (var key in file.data) {
        value = file.data[key];

        if (value && _typeof(value) === 'object' && typeof value.toString !== 'function') {
          if (value instanceof File) {
            form.append(key, value, value.name);
          } else {
            form.append(key, JSON.stringify(value));
          }
        } else if (value !== null && value !== undefined) {
          form.append(key, value);
        }
      } // Moved file.name as the first option to set the filename of the uploaded file, since file.name
      // contains the full (relative) path of the file not just the filename as in file.file.filename
      // @ts-ignore


      form.append(this.name, file.file, file.name || file.file.name || file.file.filename);
      var xhr = new XMLHttpRequest();
      xhr.open('POST', file.postAction || '');
      return this.uploadXhr(xhr, file, form);
    },
    uploadXhr: function uploadXhr(xhr, ufile, body) {
      var _this12 = this;

      var file = ufile;
      var speedTime = 0;
      var speedLoaded = 0; // 进度条

      xhr.upload.onprogress = function (e) {
        // 还未开始上传 已删除 未激活
        if (!file) {
          return;
        }

        file = _this12.get(file);

        if (!e.lengthComputable || !file || !file.fileObject || !file.active) {
          return;
        } // 进度 速度 每秒更新一次


        var speedTime2 = Math.round(Date.now() / 1000);

        if (speedTime2 === speedTime) {
          return;
        }

        speedTime = speedTime2;
        file = _this12.update(file, {
          progress: (e.loaded / e.total * 100).toFixed(2),
          speed: e.loaded - speedLoaded
        });
        speedLoaded = e.loaded;
      }; // 检查激活状态


      var interval = window.setInterval(function () {
        if (file) {
          if (file = _this12.get(file)) {
            var _file2;

            if ((_file2 = file) !== null && _file2 !== void 0 && _file2.fileObject && !file.success && !file.error && file.active) {
              return;
            }
          }
        }

        if (interval) {
          clearInterval(interval);
          interval = undefined;
        }

        try {
          xhr.abort();
          xhr.timeout = 1;
        } catch (e) {}
      }, 100);
      return new Promise(function (resolve, reject) {
        if (!file) {
          reject(new Error('not_exists'));
          return;
        }

        var complete;

        var fn = function fn(e) {
          // 已经处理过了
          if (complete) {
            return;
          }

          complete = true;

          if (interval) {
            clearInterval(interval);
            interval = undefined;
          }

          if (!file) {
            return reject(new Error('not_exists'));
          }

          file = _this12.get(file); // 不存在直接响应

          if (!file) {
            return reject(new Error('not_exists'));
          } // 不是文件对象


          if (!file.fileObject) {
            return reject(new Error('file_object'));
          } // 有错误自动响应


          if (file.error) {
            if (file.error instanceof Error) {
              return reject(file.error);
            }

            return reject(new Error(file.error));
          } // 未激活


          if (!file.active) {
            return reject(new Error('abort'));
          } // 已完成 直接相应


          if (file.success) {
            return resolve(file);
          }

          var data = {};

          switch (e.type) {
            case 'timeout':
            case 'abort':
              data.error = e.type;
              break;

            case 'error':
              if (!xhr.status) {
                data.error = 'network';
              } else if (xhr.status >= 500) {
                data.error = 'server';
              } else if (xhr.status >= 400) {
                data.error = 'denied';
              }

              break;

            default:
              if (xhr.status >= 500) {
                data.error = 'server';
              } else if (xhr.status >= 400) {
                data.error = 'denied';
              } else {
                data.progress = '100.00';
              }

          }

          if (xhr.responseText) {
            var contentType = xhr.getResponseHeader('Content-Type');

            if (contentType && contentType.indexOf('/json') !== -1) {
              data.response = JSON.parse(xhr.responseText);
            } else {
              data.response = xhr.responseText;
            }
          } // 更新
          // @ts-ignore


          file = _this12.update(file, data);

          if (!file) {
            return reject(new Error('abort'));
          } // 有错误自动响应


          if (file.error) {
            if (file.error instanceof Error) {
              return reject(file.error);
            }

            return reject(new Error(file.error));
          } // 响应


          return resolve(file);
        }; // 事件


        xhr.onload = fn;
        xhr.onerror = fn;
        xhr.onabort = fn;
        xhr.ontimeout = fn; // 超时

        if (file.timeout) {
          xhr.timeout = file.timeout;
        } // headers


        for (var key in file.headers) {
          xhr.setRequestHeader(key, file.headers[key]);
        } // 更新 xhr
        // @ts-ignore


        file = _this12.update(file, {
          xhr: xhr
        }); // 开始上传

        file && xhr.send(body);
      });
    },
    uploadHtml4: function uploadHtml4(ufile) {
      var _this13 = this;

      var file = ufile;

      if (!file) {
        return Promise.reject(new Error('not_exists'));
      }

      var onKeydown = function onKeydown(e) {
        if (e.keyCode === 27) {
          e.preventDefault();
        }
      };

      var iframe = document.createElement('iframe');
      iframe.id = 'upload-iframe-' + file.id;
      iframe.name = 'upload-iframe-' + file.id;
      iframe.src = 'about:blank';
      iframe.setAttribute('style', 'width:1px;height:1px;top:-999em;position:absolute; margin-top:-999em;');
      var form = document.createElement('form');
      form.setAttribute('action', file.postAction || '');
      form.name = 'upload-form-' + file.id;
      form.setAttribute('method', 'POST');
      form.setAttribute('target', 'upload-iframe-' + file.id);
      form.setAttribute('enctype', 'multipart/form-data');

      for (var key in file.data) {
        var value = file.data[key];

        if (value && _typeof(value) === 'object' && typeof value.toString !== 'function') {
          value = JSON.stringify(value);
        }

        if (value !== null && value !== undefined) {
          var el = document.createElement('input');
          el.type = 'hidden';
          el.name = key;
          el.value = value;
          form.appendChild(el);
        }
      }

      form.appendChild(file.el);
      document.body.appendChild(iframe).appendChild(form);

      var getResponseData = function getResponseData() {
        var _doc;

        var doc;

        try {
          if (iframe.contentWindow) {
            doc = iframe.contentWindow.document;
          }
        } catch (err) {}

        if (!doc) {
          try {
            // @ts-ignore
            doc = iframe.contentDocument ? iframe.contentDocument : iframe.document;
          } catch (err) {
            // @ts-ignore
            doc = iframe.document;
          }
        } // @ts-ignore


        if ((_doc = doc) !== null && _doc !== void 0 && _doc.body) {
          return doc.body.innerHTML;
        }

        return null;
      };

      return new Promise(function (resolve, reject) {
        setTimeout(function () {
          if (!file) {
            reject(new Error('not_exists'));
            return;
          }

          file = _this13.update(file, {
            iframe: iframe
          }); // 不存在

          if (!file) {
            return reject(new Error('not_exists'));
          } // 定时检查


          var interval = window.setInterval(function () {
            if (file) {
              if (file = _this13.get(file)) {
                if (file.fileObject && !file.success && !file.error && file.active) {
                  return;
                }
              }
            }

            if (interval) {
              clearInterval(interval);
              interval = undefined;
            } // @ts-ignore


            iframe.onabort({
              type: file ? 'abort' : 'not_exists'
            });
          }, 100);
          var complete;

          var fn = function fn(e) {
            var _file3; // 已经处理过了


            if (complete) {
              return;
            }

            complete = true;

            if (interval) {
              clearInterval(interval);
              interval = undefined;
            } // 关闭 esc 事件


            document.body.removeEventListener('keydown', onKeydown);

            if (!file) {
              return reject(new Error('not_exists'));
            }

            file = _this13.get(file); // 不存在直接响应

            if (!file) {
              return reject(new Error('not_exists'));
            } // 不是文件对象


            if (!file.fileObject) {
              return reject(new Error('file_object'));
            } // 有错误自动响应


            if (file.error) {
              if (file.error instanceof Error) {
                return reject(file.error);
              }

              return reject(new Error(file.error));
            } // 未激活


            if (!file.active) {
              return reject(new Error('abort'));
            } // 已完成 直接相应


            if (file.success) {
              return resolve(file);
            }

            var response = getResponseData();
            var data = {};

            if (typeof e === 'string') {
              return reject(new Error(e));
            }

            switch (e.type) {
              case 'abort':
                data.error = 'abort';
                break;

              case 'error':
                if (file.error) {
                  data.error = file.error;
                } else if (response === null) {
                  data.error = 'network';
                } else {
                  data.error = 'denied';
                }

                break;

              default:
                if (file.error) {
                  data.error = file.error;
                } else if (response === null) {
                  data.error = 'network';
                } else {
                  data.progress = '100.00';
                }

            }

            if (response !== null) {
              if (response && response.substr(0, 1) === '{' && response.substr(response.length - 1, 1) === '}') {
                try {
                  response = JSON.parse(response);
                } catch (err) {}
              }

              data.response = response;
            } // 更新


            file = _this13.update(file, data);

            if (!file) {
              return reject(new Error('not_exists'));
            }

            if ((_file3 = file) !== null && _file3 !== void 0 && _file3.error) {
              if (file.error instanceof Error) {
                return reject(file.error);
              }

              return reject(new Error(file.error));
            } // 响应


            return resolve(file);
          }; // 添加事件


          iframe.onload = fn;
          iframe.onerror = fn;
          iframe.onabort = fn; // 禁止 esc 键

          document.body.addEventListener('keydown', onKeydown); // 提交

          form.submit();
        }, 50);
      }).then(function (res) {
        var _iframe$parentNode;

        iframe === null || iframe === void 0 ? void 0 : (_iframe$parentNode = iframe.parentNode) === null || _iframe$parentNode === void 0 ? void 0 : _iframe$parentNode.removeChild(iframe);
        return res;
      }).catch(function (res) {
        var _iframe$parentNode2;

        iframe === null || iframe === void 0 ? void 0 : (_iframe$parentNode2 = iframe.parentNode) === null || _iframe$parentNode2 === void 0 ? void 0 : _iframe$parentNode2.removeChild(iframe);
        return res;
      });
    },
    watchActive: function watchActive(active) {
      var file;
      var index = 0;

      while (file = this.files[index]) {
        index++;
        if (!file.fileObject) ;else if (active && !this.destroy) {
          if (this.uploading >= this.thread || this.uploading && !this.features.html5) {
            break;
          }

          if (!file.active && !file.error && !file.success) {
            this.update(file, {
              active: true
            });
          }
        } else {
          if (file.active) {
            this.update(file, {
              active: false
            });
          }
        }
      }

      if (this.uploading === 0) {
        this.active = false;
      }
    },
    watchDrop: function watchDrop(newDrop) {
      var oldDrop = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : undefined;

      if (!this.features.drop) {
        return;
      }

      if (newDrop === oldDrop) {
        return;
      } // 移除挂载


      if (this.dropElement) {
        try {
          document.removeEventListener('dragenter', this.onDocumentDragenter, false);
          document.removeEventListener('dragleave', this.onDocumentDragleave, false);
          document.removeEventListener('dragover', this.onDocumentDragover, false);
          document.removeEventListener('drop', this.onDocumentDrop, false);
          this.dropElement.removeEventListener('dragenter', this.onDragenter, false);
          this.dropElement.removeEventListener('dragleave', this.onDragleave, false);
          this.dropElement.removeEventListener('dragover', this.onDragover, false);
          this.dropElement.removeEventListener('drop', this.onDrop, false);
        } catch (e) {}
      }

      var el = null;
      if (!newDrop) ;else if (typeof newDrop === 'string') {
        // @ts-ignore
        el = document.querySelector(newDrop) || this.$root.$el.querySelector(newDrop);
      } else if (newDrop === true) {
        var _el; // @ts-ignore


        el = this.$parent.$el;

        if (!el || ((_el = el) === null || _el === void 0 ? void 0 : _el.nodeType) === 8) {
          var _el2; // @ts-ignore


          el = this.$root.$el;

          if (!el || ((_el2 = el) === null || _el2 === void 0 ? void 0 : _el2.nodeType) === 8) {
            el = document.body;
          }
        }
      } else {
        el = newDrop;
      }
      this.dropElement = el;

      if (this.dropElement) {
        document.addEventListener('dragenter', this.onDocumentDragenter, false);
        document.addEventListener('dragleave', this.onDocumentDragleave, false);
        document.addEventListener('dragover', this.onDocumentDragover, false);
        document.addEventListener('drop', this.onDocumentDrop, false);
        this.dropElement.addEventListener('dragenter', this.onDragenter, false);
        this.dropElement.addEventListener('dragleave', this.onDragleave, false);
        this.dropElement.addEventListener('dragover', this.onDragover, false);
        this.dropElement.addEventListener('drop', this.onDrop, false);
      }
    },
    watchDropActive: function watchDropActive(newDropActive, oldDropActive) {
      if (newDropActive === oldDropActive) {
        return;
      } // 设置 dropElementActive false


      if (!newDropActive && this.dropElementActive) {
        this.dropElementActive = false;
      }

      if (this.dropTimeout) {
        clearTimeout(this.dropTimeout);
        this.dropTimeout = null;
      }

      if (newDropActive) {
        // @ts-ignore
        this.dropTimeout = setTimeout(this.onDocumentDrop, 1000);
      }
    },
    onDocumentDragenter: function onDocumentDragenter(e) {
      var _dt$files, _dt$types;

      if (this.dropActive) {
        return;
      }

      if (!e.dataTransfer) {
        return;
      }

      var dt = e.dataTransfer;

      if (dt !== null && dt !== void 0 && (_dt$files = dt.files) !== null && _dt$files !== void 0 && _dt$files.length) {
        this.dropActive = true;
      } else if (!dt.types) {
        this.dropActive = true;
      } else if (dt.types.indexOf && dt.types.indexOf('Files') !== -1) {
        this.dropActive = true; // @ts-ignore
      } else if ((_dt$types = dt.types) !== null && _dt$types !== void 0 && _dt$types.contains && dt.types.contains('Files')) {
        this.dropActive = true;
      }

      if (this.dropActive) {
        this.watchDropActive(true);
      }
    },
    onDocumentDragleave: function onDocumentDragleave(e) {
      if (!this.dropActive) {
        return;
      } // @ts-ignore


      if (e.target === e.explicitOriginalTarget || !e.fromElement && (e.clientX <= 0 || e.clientY <= 0 || e.clientX >= window.innerWidth || e.clientY >= window.innerHeight)) {
        this.dropActive = false;
        this.watchDropActive(false);
      }
    },
    onDocumentDragover: function onDocumentDragover() {
      this.watchDropActive(true);
    },
    onDocumentDrop: function onDocumentDrop() {
      this.dropActive = false;
      this.watchDropActive(false);
    },
    onDragenter: function onDragenter(e) {
      if (!this.dropActive || this.dropElementActive) {
        return;
      }

      this.dropElementActive = true;
    },
    onDragleave: function onDragleave(e) {
      var _this$dropElement;

      if (!this.dropElementActive) {
        return;
      }

      var related = e.relatedTarget;

      if (!related) {
        this.dropElementActive = false;
      } else if ((_this$dropElement = this.dropElement) !== null && _this$dropElement !== void 0 && _this$dropElement.contains) {
        if (!this.dropElement.contains(related)) {
          this.dropElementActive = false;
        }
      } else {
        var child = related;

        while (child) {
          if (child === this.dropElement) {
            break;
          } // @ts-ignore


          child = child.parentNode;
        }

        if (child !== this.dropElement) {
          this.dropElementActive = false;
        }
      }
    },
    onDragover: function onDragover(e) {
      e.preventDefault();
    },
    onDrop: function onDrop(e) {
      e.preventDefault();
      e.dataTransfer && this.addDataTransfer(e.dataTransfer);
    },
    inputOnChange: async function inputOnChange(e) {
      var _this14 = this;

      if (!(e.target instanceof HTMLInputElement)) {
        return Promise.reject(new Error("not HTMLInputElement"));
      }

      e.target;

      var reinput = function reinput(res) {
        _this14.reload = true; // @ts-ignore

        _this14.$nextTick(function () {
          _this14.reload = false;
        });

        return res;
      };

      return this.addInputFile(e.target).then(reinput).catch(reinput);
    },
    isRelatedTargetSupported: function isRelatedTargetSupported() {
      try {
        // 创建一个模拟的 MouseEvent
        var event = new MouseEvent('mouseout', {
          relatedTarget: document.body
        });
        return 'relatedTarget' in event; // 检查 `relatedTarget` 属性是否存在
      } catch (e) {
        // 如果 MouseEvent 不受支持，或者无法设置 relatedTarget
        return false;
      }
    }
  }
});
var _hoisted_1 = ["for"];
var _hoisted_2 = ["name", "id", "accept", "capture", "disabled", "webkitdirectory", "allowdirs", "directory", "multiple"];

function render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("span", {
    class: normalizeClass(_ctx.className)
  }, [renderSlot(_ctx.$slots, "default"), createElementVNode("label", {
    for: _ctx.forId
  }, null, 8, _hoisted_1), !_ctx.reload ? (openBlock(), createElementBlock("input", {
    key: 0,
    ref: "input",
    type: "file",
    name: _ctx.name,
    id: _ctx.forId,
    accept: _ctx.accept,
    capture: _ctx.capture,
    disabled: _ctx.disabled,
    webkitdirectory: _ctx.iDirectory,
    allowdirs: _ctx.iDirectory,
    directory: _ctx.iDirectory,
    multiple: _ctx.multiple && _ctx.features.html5,
    onChange: _cache[0] || (_cache[0] = function () {
      return _ctx.inputOnChange && _ctx.inputOnChange.apply(_ctx, arguments);
    })
  }, null, 40, _hoisted_2)) : createCommentVNode("", true)], 2);
}

function styleInject(css, ref) {
  if (ref === void 0) ref = {};
  var insertAt = ref.insertAt;

  if (!css || typeof document === 'undefined') {
    return;
  }

  var head = document.head || document.getElementsByTagName('head')[0];
  var style = document.createElement('style');
  style.type = 'text/css';

  if (insertAt === 'top') {
    if (head.firstChild) {
      head.insertBefore(style, head.firstChild);
    } else {
      head.appendChild(style);
    }
  } else {
    head.appendChild(style);
  }

  if (style.styleSheet) {
    style.styleSheet.cssText = css;
  } else {
    style.appendChild(document.createTextNode(css));
  }
}

var css_248z = "\n.file-uploads {\n  overflow: hidden;\n  position: relative;\n  text-align: center;\n  display: inline-block;\n}\n.file-uploads.file-uploads-html4 input,\n.file-uploads.file-uploads-html5 label {\n  /* background fix ie  click */\n  background: #fff;\n  opacity: 0;\n  font-size: 20em;\n  z-index: 1;\n  top: 0;\n  left: 0;\n  right: 0;\n  bottom: 0;\n  position: absolute;\n  width: 100%;\n  height: 100%;\n}\n.file-uploads.file-uploads-html5 input,\n.file-uploads.file-uploads-html4 label {\n  /* background fix ie  click */\n  position: absolute;\n  background: rgba(255, 255, 255, 0);\n  overflow: hidden;\n  position: fixed;\n  width: 1px;\n  height: 1px;\n  z-index: -1;\n  opacity: 0;\n}\n";
styleInject(css_248z);
script.render = render;
export { script as default };
//# sourceMappingURL=vue-upload-component.esm.js.map
