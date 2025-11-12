"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.ts
var src_exports = {};
__export(src_exports, {
  ANSI_ESCAPE: () => ANSI_ESCAPE,
  ANSI_ESCAPE_CODES: () => ANSI_ESCAPE_CODES,
  BaseEventMap: () => BaseEventMap,
  Concurrency: () => Concurrency,
  DefaultRenderer: () => DefaultRenderer,
  EventManager: () => EventManager,
  LISTR_DEFAULT_RENDERER_STYLE: () => LISTR_DEFAULT_RENDERER_STYLE,
  LISTR_LOGGER_STDERR_LEVELS: () => LISTR_LOGGER_STDERR_LEVELS,
  LISTR_LOGGER_STYLE: () => LISTR_LOGGER_STYLE,
  Listr: () => Listr,
  ListrDefaultRendererLogLevels: () => ListrDefaultRendererLogLevels,
  ListrEnvironmentVariables: () => ListrEnvironmentVariables,
  ListrError: () => ListrError,
  ListrErrorTypes: () => ListrErrorTypes,
  ListrEventManager: () => ListrEventManager,
  ListrEventType: () => ListrEventType,
  ListrLogLevels: () => ListrLogLevels,
  ListrLogger: () => ListrLogger,
  ListrRendererError: () => ListrRendererError,
  ListrTaskEventManager: () => ListrTaskEventManager,
  ListrTaskEventType: () => ListrTaskEventType,
  ListrTaskState: () => ListrTaskState,
  Manager: () => Manager,
  PRESET_TIMER: () => PRESET_TIMER,
  PRESET_TIMESTAMP: () => PRESET_TIMESTAMP,
  ProcessOutput: () => ProcessOutput,
  ProcessOutputBuffer: () => ProcessOutputBuffer,
  ProcessOutputStream: () => ProcessOutputStream,
  PromptError: () => PromptError,
  SilentRenderer: () => SilentRenderer,
  SimpleRenderer: () => SimpleRenderer,
  Spinner: () => Spinner,
  TestRenderer: () => TestRenderer,
  TestRendererSerializer: () => TestRendererSerializer,
  VerboseRenderer: () => VerboseRenderer,
  assertFunctionOrSelf: () => assertFunctionOrSelf,
  cleanseAnsi: () => cleanseAnsi,
  cloneObject: () => cloneObject,
  color: () => color,
  createPrompt: () => createPrompt,
  createWritable: () => createWritable,
  delay: () => delay,
  figures: () => figures,
  getRenderer: () => getRenderer,
  getRendererClass: () => getRendererClass,
  indent: () => indent,
  isObservable: () => isObservable,
  isUnicodeSupported: () => isUnicodeSupported,
  parseTimer: () => parseTimer,
  parseTimestamp: () => parseTimestamp,
  splat: () => splat
});
module.exports = __toCommonJS(src_exports);

// src/constants/ansi-escape-codes.constants.ts
var ANSI_ESCAPE = "\x1B[";
var ANSI_ESCAPE_CODES = {
  CURSOR_HIDE: ANSI_ESCAPE + "?25l",
  CURSOR_SHOW: ANSI_ESCAPE + "?25h"
};

// src/constants/environment-variables.constants.ts
var ListrEnvironmentVariables = /* @__PURE__ */ ((ListrEnvironmentVariables2) => {
  ListrEnvironmentVariables2["DISABLE_COLOR"] = "LISTR_DISABLE_COLOR";
  ListrEnvironmentVariables2["FORCE_UNICODE"] = "LISTR_FORCE_UNICODE";
  ListrEnvironmentVariables2["FORCE_COLOR"] = "FORCE_COLOR";
  return ListrEnvironmentVariables2;
})(ListrEnvironmentVariables || {});

// src/constants/listr-error.constants.ts
var ListrErrorTypes = /* @__PURE__ */ ((ListrErrorTypes2) => {
  ListrErrorTypes2["WILL_RETRY"] = "WILL_RETRY";
  ListrErrorTypes2["WILL_ROLLBACK"] = "WILL_ROLLBACK";
  ListrErrorTypes2["HAS_FAILED_TO_ROLLBACK"] = "HAS_FAILED_TO_ROLLBACK";
  ListrErrorTypes2["HAS_FAILED"] = "HAS_FAILED";
  ListrErrorTypes2["HAS_FAILED_WITHOUT_ERROR"] = "HAS_FAILED_WITHOUT_ERROR";
  return ListrErrorTypes2;
})(ListrErrorTypes || {});

// src/constants/listr-events.constants.ts
var ListrEventType = /* @__PURE__ */ ((ListrEventType2) => {
  ListrEventType2["SHOULD_REFRESH_RENDER"] = "SHOUD_REFRESH_RENDER";
  return ListrEventType2;
})(ListrEventType || {});

// src/constants/listr-task-events.constants.ts
var ListrTaskEventType = /* @__PURE__ */ ((ListrTaskEventType2) => {
  ListrTaskEventType2["TITLE"] = "TITLE";
  ListrTaskEventType2["STATE"] = "STATE";
  ListrTaskEventType2["ENABLED"] = "ENABLED";
  ListrTaskEventType2["SUBTASK"] = "SUBTASK";
  ListrTaskEventType2["PROMPT"] = "PROMPT";
  ListrTaskEventType2["OUTPUT"] = "OUTPUT";
  ListrTaskEventType2["MESSAGE"] = "MESSAGE";
  ListrTaskEventType2["CLOSED"] = "CLOSED";
  return ListrTaskEventType2;
})(ListrTaskEventType || {});

// src/constants/listr-task-state.constants.ts
var ListrTaskState = /* @__PURE__ */ ((ListrTaskState2) => {
  ListrTaskState2["WAITING"] = "WAITING";
  ListrTaskState2["STARTED"] = "STARTED";
  ListrTaskState2["COMPLETED"] = "COMPLETED";
  ListrTaskState2["FAILED"] = "FAILED";
  ListrTaskState2["SKIPPED"] = "SKIPPED";
  ListrTaskState2["ROLLING_BACK"] = "ROLLING_BACK";
  ListrTaskState2["ROLLED_BACK"] = "ROLLED_BACK";
  ListrTaskState2["RETRY"] = "RETRY";
  ListrTaskState2["PAUSED"] = "PAUSED";
  ListrTaskState2["PROMPT"] = "PROMPT";
  ListrTaskState2["PROMPT_COMPLETED"] = "PROMPT_COMPLETED";
  return ListrTaskState2;
})(ListrTaskState || {});

// src/lib/event-manager.ts
var import_eventemitter3 = __toESM(require("eventemitter3"), 1);
var _EventManager = class _EventManager {
  constructor() {
    this.emitter = new import_eventemitter3.default();
  }
  emit(dispatch, args) {
    this.emitter.emit(dispatch, args);
  }
  on(dispatch, handler) {
    this.emitter.addListener(dispatch, handler);
  }
  once(dispatch, handler) {
    this.emitter.once(dispatch, handler);
  }
  off(dispatch, handler) {
    this.emitter.off(dispatch, handler);
  }
  complete() {
    this.emitter.removeAllListeners();
  }
};
__name(_EventManager, "EventManager");
var EventManager = _EventManager;

// src/interfaces/event.interface.ts
var _BaseEventMap = class _BaseEventMap {
};
__name(_BaseEventMap, "BaseEventMap");
var BaseEventMap = _BaseEventMap;

// src/utils/environment/is-observable.ts
function isObservable(obj) {
  return !!obj && typeof obj.lift === "function" && typeof obj.subscribe === "function";
}
__name(isObservable, "isObservable");

// src/utils/environment/is-unicode-supported.ts
function isUnicodeSupported() {
  return !!process.env["LISTR_FORCE_UNICODE" /* FORCE_UNICODE */] || process.platform !== "win32" || !!process.env.CI || !!process.env.WT_SESSION || process.env.TERM_PROGRAM === "vscode" || process.env.TERM === "xterm-256color" || process.env.TERM === "alacritty";
}
__name(isUnicodeSupported, "isUnicodeSupported");

// src/utils/format/cleanse-ansi.constants.ts
var CLEAR_LINE_REGEX = "(?:\\u001b|\\u009b)\\[[\\=><~/#&.:=?%@~_-]*[0-9]*[\\a-ln-tqyz=><~/#&.:=?%@~_-]+";
var BELL_REGEX = /\u0007/;

// src/utils/format/cleanse-ansi.ts
function cleanseAnsi(chunk) {
  return String(chunk).replace(new RegExp(CLEAR_LINE_REGEX, "gmi"), "").replace(new RegExp(BELL_REGEX, "gmi"), "").trim();
}
__name(cleanseAnsi, "cleanseAnsi");

// src/utils/format/color.ts
var import_colorette = require("colorette");
var color = (0, import_colorette.createColors)({ useColor: !process.env["LISTR_DISABLE_COLOR" /* DISABLE_COLOR */] });

// src/utils/format/indent.ts
function indent(string, count) {
  return string.replace(/^(?!\s*$)/gm, " ".repeat(count));
}
__name(indent, "indent");

// src/utils/format/figures.ts
var FIGURES_MAIN = {
  warning: "\u26A0",
  cross: "\u2716",
  arrowDown: "\u2193",
  tick: "\u2714",
  arrowRight: "\u2192",
  pointer: "\u276F",
  checkboxOn: "\u2612",
  arrowLeft: "\u2190",
  squareSmallFilled: "\u25FC",
  pointerSmall: "\u203A"
};
var FIGURES_FALLBACK = {
  ...FIGURES_MAIN,
  warning: "\u203C",
  cross: "\xD7",
  tick: "\u221A",
  pointer: ">",
  checkboxOn: "[\xD7]",
  squareSmallFilled: "\u25A0"
};
var figures = isUnicodeSupported() ? FIGURES_MAIN : FIGURES_FALLBACK;

// src/utils/format/splat.ts
var import_util = require("util");
function splat(message, ...splat2) {
  return (0, import_util.format)(String(message), ...splat2);
}
__name(splat, "splat");

// src/utils/logger/logger.constants.ts
var ListrLogLevels = /* @__PURE__ */ ((ListrLogLevels2) => {
  ListrLogLevels2["STARTED"] = "STARTED";
  ListrLogLevels2["COMPLETED"] = "COMPLETED";
  ListrLogLevels2["FAILED"] = "FAILED";
  ListrLogLevels2["SKIPPED"] = "SKIPPED";
  ListrLogLevels2["OUTPUT"] = "OUTPUT";
  ListrLogLevels2["TITLE"] = "TITLE";
  ListrLogLevels2["ROLLBACK"] = "ROLLBACK";
  ListrLogLevels2["RETRY"] = "RETRY";
  ListrLogLevels2["PROMPT"] = "PROMPT";
  ListrLogLevels2["PAUSED"] = "PAUSED";
  return ListrLogLevels2;
})(ListrLogLevels || {});
var LISTR_LOGGER_STYLE = {
  icon: {
    ["STARTED" /* STARTED */]: figures.pointer,
    ["FAILED" /* FAILED */]: figures.cross,
    ["SKIPPED" /* SKIPPED */]: figures.arrowDown,
    ["COMPLETED" /* COMPLETED */]: figures.tick,
    ["OUTPUT" /* OUTPUT */]: figures.pointerSmall,
    ["TITLE" /* TITLE */]: figures.arrowRight,
    ["RETRY" /* RETRY */]: figures.warning,
    ["ROLLBACK" /* ROLLBACK */]: figures.arrowLeft,
    ["PAUSED" /* PAUSED */]: figures.squareSmallFilled
  },
  color: {
    ["STARTED" /* STARTED */]: color.yellow,
    ["FAILED" /* FAILED */]: color.red,
    ["SKIPPED" /* SKIPPED */]: color.yellow,
    ["COMPLETED" /* COMPLETED */]: color.green,
    ["RETRY" /* RETRY */]: color.yellowBright,
    ["ROLLBACK" /* ROLLBACK */]: color.redBright,
    ["PAUSED" /* PAUSED */]: color.yellowBright
  }
};
var LISTR_LOGGER_STDERR_LEVELS = ["RETRY" /* RETRY */, "ROLLBACK" /* ROLLBACK */, "FAILED" /* FAILED */];

// src/utils/logger/logger.ts
var import_os = require("os");
var _ListrLogger = class _ListrLogger {
  constructor(options) {
    this.options = options;
    this.options = {
      useIcons: true,
      toStderr: [],
      ...options ?? {}
    };
    this.options.fields ??= {};
    this.options.fields.prefix ??= [];
    this.options.fields.suffix ??= [];
    this.process = this.options.processOutput ?? new ProcessOutput();
  }
  log(level, message, options) {
    const output = this.format(level, message, options);
    if (this.options.toStderr.includes(level)) {
      this.process.toStderr(output);
      return;
    }
    this.process.toStdout(output);
  }
  toStdout(message, options, eol = true) {
    this.process.toStdout(this.format(null, message, options), eol);
  }
  toStderr(message, options, eol = true) {
    this.process.toStderr(this.format(null, message, options), eol);
  }
  wrap(message, options) {
    if (!message) {
      return message;
    }
    return this.applyFormat(`[${message}]`, options);
  }
  splat(...args) {
    const message = args.shift() ?? "";
    return args.length === 0 ? message : splat(message, args);
  }
  suffix(message, ...suffixes) {
    suffixes.filter(Boolean).forEach((suffix) => {
      message += this.spacing(message);
      if (typeof suffix === "string") {
        message += this.wrap(suffix);
      } else if (typeof suffix === "object") {
        suffix.args ??= [];
        if (typeof suffix.condition === "function" ? !suffix.condition(...suffix.args) : !(suffix.condition ?? true)) {
          return message;
        }
        message += this.wrap(typeof suffix.field === "function" ? suffix.field(...suffix.args) : suffix.field, {
          format: suffix?.format(...suffix.args)
        });
      }
    });
    return message;
  }
  prefix(message, ...prefixes) {
    prefixes.filter(Boolean).forEach((prefix) => {
      message = this.spacing(message) + message;
      if (typeof prefix === "string") {
        message = this.wrap(prefix) + message;
      } else if (typeof prefix === "object") {
        prefix.args ??= [];
        if (typeof prefix.condition === "function" ? !prefix.condition(...prefix.args) : !(prefix.condition ?? true)) {
          return message;
        }
        message = this.wrap(typeof prefix.field === "function" ? prefix.field(...prefix.args) : prefix.field, {
          format: prefix?.format()
        }) + message;
      }
    });
    return message;
  }
  fields(message, options) {
    if (this.options?.fields?.prefix) {
      message = this.prefix(message, ...this.options.fields.prefix);
    }
    if (options?.prefix) {
      message = this.prefix(message, ...options.prefix);
    }
    if (options?.suffix) {
      message = this.suffix(message, ...options.suffix);
    }
    if (this.options?.fields?.suffix) {
      message = this.suffix(message, ...this.options.fields.suffix);
    }
    return message;
  }
  icon(level, icon) {
    if (!level) {
      return null;
    }
    icon ||= this.options.icon?.[level];
    const coloring = this.options.color?.[level];
    if (icon && coloring) {
      icon = coloring(icon);
    }
    return icon;
  }
  format(level, message, options) {
    if (!Array.isArray(message)) {
      message = [message];
    }
    message = this.splat(message.shift(), ...message).toString().split(import_os.EOL).filter((m) => !m || m.trim() !== "").map((m) => {
      return this.style(
        level,
        this.fields(m, {
          prefix: Array.isArray(options?.prefix) ? options.prefix : [options?.prefix],
          suffix: Array.isArray(options?.suffix) ? options.suffix : [options?.suffix]
        })
      );
    }).join(import_os.EOL);
    return message;
  }
  style(level, message) {
    if (!level || !message) {
      return message;
    }
    const icon = this.icon(level, !this.options.useIcons && this.wrap(level));
    if (icon) {
      message = icon + " " + message;
    }
    return message;
  }
  applyFormat(message, options) {
    if (options?.format) {
      return options.format(message);
    }
    return message;
  }
  spacing(message) {
    return typeof message === "undefined" || message.trim() === "" ? "" : " ";
  }
};
__name(_ListrLogger, "ListrLogger");
var ListrLogger = _ListrLogger;

// src/utils/process-output/process-output-buffer.ts
var import_string_decoder = require("string_decoder");
var _ProcessOutputBuffer = class _ProcessOutputBuffer {
  constructor(options) {
    this.options = options;
    this.buffer = [];
    this.decoder = new import_string_decoder.StringDecoder();
  }
  get all() {
    return this.buffer;
  }
  get last() {
    return this.buffer.at(-1);
  }
  get length() {
    return this.buffer.length;
  }
  write(data, ...args) {
    const callback = args[args.length - 1];
    this.buffer.push({
      time: Date.now(),
      stream: this.options?.stream,
      entry: this.decoder.write(typeof data === "string" ? Buffer.from(data, typeof args[0] === "string" ? args[0] : void 0) : Buffer.from(data))
    });
    if (this.options?.limit) {
      this.buffer = this.buffer.slice(-this.options.limit);
    }
    if (typeof callback === "function") {
      callback();
    }
    return true;
  }
  reset() {
    this.buffer = [];
  }
};
__name(_ProcessOutputBuffer, "ProcessOutputBuffer");
var ProcessOutputBuffer = _ProcessOutputBuffer;

// src/utils/process-output/process-output-stream.ts
var _ProcessOutputStream = class _ProcessOutputStream {
  constructor(stream) {
    this.stream = stream;
    this.method = stream.write;
    this.buffer = new ProcessOutputBuffer({ stream });
  }
  get out() {
    return Object.assign({}, this.stream, {
      write: this.write.bind(this)
    });
  }
  hijack() {
    this.stream.write = this.buffer.write.bind(this.buffer);
  }
  release() {
    this.stream.write = this.method;
    const buffer = [...this.buffer.all];
    this.buffer.reset();
    return buffer;
  }
  write(...args) {
    return this.method.apply(this.stream, args);
  }
};
__name(_ProcessOutputStream, "ProcessOutputStream");
var ProcessOutputStream = _ProcessOutputStream;

// src/utils/process-output/process-output.ts
var import_os2 = require("os");
var _ProcessOutput = class _ProcessOutput {
  constructor(stdout, stderr, options) {
    this.options = options;
    this.stream = {
      stdout: new ProcessOutputStream(stdout ?? process.stdout),
      stderr: new ProcessOutputStream(stderr ?? process.stderr)
    };
    this.options = {
      dump: ["stdout", "stderr"],
      leaveEmptyLine: true,
      ...options
    };
  }
  get stdout() {
    return this.stream.stdout.out;
  }
  get stderr() {
    return this.stream.stderr.out;
  }
  hijack() {
    if (this.active) {
      throw new Error("ProcessOutput has been already hijacked!");
    }
    this.stream.stdout.write(ANSI_ESCAPE_CODES.CURSOR_HIDE);
    Object.values(this.stream).forEach((stream) => stream.hijack());
    this.active = true;
  }
  release() {
    const output = Object.entries(this.stream).map(([name, stream]) => ({ name, buffer: stream.release() })).filter((output2) => this.options.dump.includes(output2.name)).flatMap((output2) => output2.buffer).sort((a, b) => a.time - b.time).map((message) => {
      return {
        ...message,
        entry: cleanseAnsi(message.entry)
      };
    }).filter((message) => message.entry);
    if (output.length > 0) {
      if (this.options.leaveEmptyLine) {
        this.stdout.write(import_os2.EOL);
      }
      output.forEach((message) => {
        const stream = message.stream ?? this.stdout;
        stream.write(message.entry + import_os2.EOL);
      });
    }
    this.stream.stdout.write(ANSI_ESCAPE_CODES.CURSOR_SHOW);
    this.active = false;
  }
  toStdout(buffer, eol = true) {
    if (eol) {
      buffer = buffer + import_os2.EOL;
    }
    return this.stream.stdout.write(buffer);
  }
  toStderr(buffer, eol = true) {
    if (eol) {
      buffer = buffer + import_os2.EOL;
    }
    return this.stream.stderr.write(buffer);
  }
};
__name(_ProcessOutput, "ProcessOutput");
var ProcessOutput = _ProcessOutput;

// src/utils/process-output/writable.ts
var import_stream = require("stream");
function createWritable(cb) {
  const writable = new import_stream.Writable();
  writable.write = (chunk) => {
    cb(chunk.toString());
    return true;
  };
  return writable;
}
__name(createWritable, "createWritable");

// src/utils/ui/spinner.ts
var _Spinner = class _Spinner {
  constructor() {
    this.spinner = !isUnicodeSupported() ? ["-", "\\", "|", "/"] : ["\u280B", "\u2819", "\u2839", "\u2838", "\u283C", "\u2834", "\u2826", "\u2827", "\u2807", "\u280F"];
    this.spinnerPosition = 0;
  }
  spin() {
    this.spinnerPosition = ++this.spinnerPosition % this.spinner.length;
  }
  fetch() {
    return this.spinner[this.spinnerPosition];
  }
  isRunning() {
    return !!this.id;
  }
  start(cb, interval = 100) {
    this.id = setInterval(() => {
      this.spin();
      if (cb) {
        cb();
      }
    }, interval);
  }
  stop() {
    clearInterval(this.id);
  }
};
__name(_Spinner, "Spinner");
var Spinner = _Spinner;

// src/utils/ui/prompt.ts
async function createPrompt(options, settings) {
  settings = {
    ...settings
  };
  if (!Array.isArray(options)) {
    options = [{ ...options, name: "default" }];
  } else if (options.length === 1) {
    options = options.map((option) => {
      return { ...option, name: "default" };
    });
  }
  options = options.map((option) => {
    return {
      onCancel: () => {
        const error = new PromptError("Cancelled prompt.");
        if (this instanceof TaskWrapper) {
          this.task.prompt = error;
        } else {
          throw error;
        }
        return true;
      },
      ...option,
      // this is for outside calls, if it is not called from taskwrapper with bind
      stdout: this instanceof TaskWrapper ? settings?.stdout ?? this.stdout("PROMPT" /* PROMPT */) : process.stdout
    };
  });
  let enquirer;
  if (settings?.enquirer) {
    enquirer = settings.enquirer;
  } else {
    try {
      enquirer = await import("enquirer").then((imported) => imported.default ? new imported.default() : new imported());
    } catch (e) {
      if (this instanceof TaskWrapper) {
        this.task.prompt = new PromptError("Enquirer is a peer dependency that must be installed separately.");
      }
      throw e;
    }
  }
  let state;
  if (this instanceof TaskWrapper) {
    state = this.task.state;
    this.task.state$ = "PROMPT" /* PROMPT */;
    enquirer.on("prompt", (prompt) => this.task.prompt = prompt).on("submit", () => this.task.prompt = void 0);
    this.task.on("STATE" /* STATE */, (event) => {
      if (event === "SKIPPED" /* SKIPPED */ && this.task.prompt && !(this.task.prompt instanceof PromptError)) {
        this.task.prompt.submit();
      }
    });
  }
  const response = await enquirer.prompt(options);
  if (this instanceof TaskWrapper) {
    this.task.state$ = "PROMPT_COMPLETED" /* PROMPT_COMPLETED */;
    this.task.state = state;
  }
  if (options.length === 1) {
    return response.default;
  } else {
    return response;
  }
}
__name(createPrompt, "createPrompt");

// src/renderer/default/renderer.constants.ts
var ListrDefaultRendererLogLevels = /* @__PURE__ */ ((ListrDefaultRendererLogLevels2) => {
  ListrDefaultRendererLogLevels2["SKIPPED_WITH_COLLAPSE"] = "SKIPPED_WITH_COLLAPSE";
  ListrDefaultRendererLogLevels2["SKIPPED_WITHOUT_COLLAPSE"] = "SKIPPED_WITHOUT_COLLAPSE";
  ListrDefaultRendererLogLevels2["OUTPUT"] = "OUTPUT";
  ListrDefaultRendererLogLevels2["OUTPUT_WITH_BOTTOMBAR"] = "OUTPUT_WITH_BOTTOMBAR";
  ListrDefaultRendererLogLevels2["PENDING"] = "PENDING";
  ListrDefaultRendererLogLevels2["COMPLETED"] = "COMPLETED";
  ListrDefaultRendererLogLevels2["COMPLETED_WITH_FAILED_SUBTASKS"] = "COMPLETED_WITH_FAILED_SUBTASKS";
  ListrDefaultRendererLogLevels2["COMPLETED_WITH_FAILED_SISTER_TASKS"] = "COMPLETED_WITH_SISTER_TASKS_FAILED";
  ListrDefaultRendererLogLevels2["RETRY"] = "RETRY";
  ListrDefaultRendererLogLevels2["ROLLING_BACK"] = "ROLLING_BACK";
  ListrDefaultRendererLogLevels2["ROLLED_BACK"] = "ROLLED_BACK";
  ListrDefaultRendererLogLevels2["FAILED"] = "FAILED";
  ListrDefaultRendererLogLevels2["FAILED_WITH_FAILED_SUBTASKS"] = "FAILED_WITH_SUBTASKS";
  ListrDefaultRendererLogLevels2["WAITING"] = "WAITING";
  ListrDefaultRendererLogLevels2["PAUSED"] = "PAUSED";
  return ListrDefaultRendererLogLevels2;
})(ListrDefaultRendererLogLevels || {});
var LISTR_DEFAULT_RENDERER_STYLE = {
  icon: {
    ["SKIPPED_WITH_COLLAPSE" /* SKIPPED_WITH_COLLAPSE */]: figures.arrowDown,
    ["SKIPPED_WITHOUT_COLLAPSE" /* SKIPPED_WITHOUT_COLLAPSE */]: figures.warning,
    ["OUTPUT" /* OUTPUT */]: figures.pointerSmall,
    ["OUTPUT_WITH_BOTTOMBAR" /* OUTPUT_WITH_BOTTOMBAR */]: figures.pointerSmall,
    ["PENDING" /* PENDING */]: figures.pointer,
    ["COMPLETED" /* COMPLETED */]: figures.tick,
    ["COMPLETED_WITH_FAILED_SUBTASKS" /* COMPLETED_WITH_FAILED_SUBTASKS */]: figures.warning,
    ["COMPLETED_WITH_SISTER_TASKS_FAILED" /* COMPLETED_WITH_FAILED_SISTER_TASKS */]: figures.squareSmallFilled,
    ["RETRY" /* RETRY */]: figures.warning,
    ["ROLLING_BACK" /* ROLLING_BACK */]: figures.warning,
    ["ROLLED_BACK" /* ROLLED_BACK */]: figures.arrowLeft,
    ["FAILED" /* FAILED */]: figures.cross,
    ["FAILED_WITH_SUBTASKS" /* FAILED_WITH_FAILED_SUBTASKS */]: figures.pointer,
    ["WAITING" /* WAITING */]: figures.squareSmallFilled,
    ["PAUSED" /* PAUSED */]: figures.squareSmallFilled
  },
  color: {
    ["SKIPPED_WITH_COLLAPSE" /* SKIPPED_WITH_COLLAPSE */]: color.yellow,
    ["SKIPPED_WITHOUT_COLLAPSE" /* SKIPPED_WITHOUT_COLLAPSE */]: color.yellow,
    ["PENDING" /* PENDING */]: color.yellow,
    ["COMPLETED" /* COMPLETED */]: color.green,
    ["COMPLETED_WITH_FAILED_SUBTASKS" /* COMPLETED_WITH_FAILED_SUBTASKS */]: color.yellow,
    ["COMPLETED_WITH_SISTER_TASKS_FAILED" /* COMPLETED_WITH_FAILED_SISTER_TASKS */]: color.red,
    ["RETRY" /* RETRY */]: color.yellowBright,
    ["ROLLING_BACK" /* ROLLING_BACK */]: color.redBright,
    ["ROLLED_BACK" /* ROLLED_BACK */]: color.redBright,
    ["FAILED" /* FAILED */]: color.red,
    ["FAILED_WITH_SUBTASKS" /* FAILED_WITH_FAILED_SUBTASKS */]: color.red,
    ["WAITING" /* WAITING */]: color.dim,
    ["PAUSED" /* PAUSED */]: color.yellowBright
  }
};

// src/renderer/default/renderer.ts
var import_os3 = require("os");

// src/presets/timer/parser.ts
function parseTimer(duration) {
  const seconds = Math.floor(duration / 1e3);
  const minutes = Math.floor(seconds / 60);
  let parsedTime;
  if (seconds === 0 && minutes === 0) {
    parsedTime = `0.${Math.floor(duration / 100)}s`;
  }
  if (seconds > 0) {
    parsedTime = `${seconds % 60}s`;
  }
  if (minutes > 0) {
    parsedTime = `${minutes}m${parsedTime}`;
  }
  return parsedTime;
}
__name(parseTimer, "parseTimer");

// src/presets/timer/preset.ts
var PRESET_TIMER = {
  condition: true,
  field: parseTimer,
  format: () => color.dim
};

// src/presets/timestamp/parser.ts
function parseTimestamp() {
  const now = /* @__PURE__ */ new Date();
  return String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0") + ":" + String(now.getSeconds()).padStart(2, "0");
}
__name(parseTimestamp, "parseTimestamp");

// src/presets/timestamp/preset.ts
var PRESET_TIMESTAMP = {
  condition: true,
  field: parseTimestamp,
  format: () => color.dim
};

// src/renderer/default/renderer.ts
var _DefaultRenderer = class _DefaultRenderer {
  constructor(tasks, options, events) {
    this.tasks = tasks;
    this.options = options;
    this.events = events;
    this.bottom = /* @__PURE__ */ new Map();
    this.cache = {
      output: /* @__PURE__ */ new Map(),
      rendererOptions: /* @__PURE__ */ new Map(),
      rendererTaskOptions: /* @__PURE__ */ new Map()
    };
    this.options = {
      ..._DefaultRenderer.rendererOptions,
      ...this.options,
      icon: {
        ...LISTR_DEFAULT_RENDERER_STYLE.icon,
        ...options?.icon ?? {}
      },
      color: {
        ...LISTR_DEFAULT_RENDERER_STYLE.color,
        ...options?.color ?? {}
      }
    };
    this.spinner = this.options.spinner ?? new Spinner();
    this.logger = this.options.logger ?? new ListrLogger({ useIcons: true, toStderr: [] });
    this.logger.options.icon = this.options.icon;
    this.logger.options.color = this.options.color;
  }
  isBottomBar(task) {
    const bottomBar = this.cache.rendererTaskOptions.get(task.id).bottomBar;
    return typeof bottomBar === "number" && bottomBar !== 0 || typeof bottomBar === "boolean" && bottomBar !== false || !task.hasTitle();
  }
  async render() {
    const { createLogUpdate } = await import("log-update");
    const { default: truncate } = await import("cli-truncate");
    const { default: wrap } = await import("wrap-ansi");
    this.updater = createLogUpdate(this.logger.process.stdout);
    this.truncate = truncate;
    this.wrap = wrap;
    this.logger.process.hijack();
    if (!this.options?.lazy) {
      this.spinner.start(() => {
        this.update();
      });
    }
    this.events.on("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */, () => {
      this.update();
    });
  }
  update() {
    this.updater(this.create());
  }
  end() {
    this.spinner.stop();
    this.updater.clear();
    this.updater.done();
    if (!this.options.clearOutput) {
      this.logger.process.toStdout(this.create({ prompt: false }));
    }
    this.logger.process.release();
  }
  create(options) {
    options = {
      tasks: true,
      bottomBar: true,
      prompt: true,
      ...options
    };
    const render = [];
    const renderTasks = this.renderer(this.tasks);
    const renderBottomBar = this.renderBottomBar();
    const renderPrompt = this.renderPrompt();
    if (options.tasks && renderTasks.length > 0) {
      render.push(...renderTasks);
    }
    if (options.bottomBar && renderBottomBar.length > 0) {
      if (render.length > 0) {
        render.push("");
      }
      render.push(...renderBottomBar);
    }
    if (options.prompt && renderPrompt.length > 0) {
      if (render.length > 0) {
        render.push("");
      }
      render.push(...renderPrompt);
    }
    return render.join(import_os3.EOL);
  }
  // eslint-disable-next-line complexity
  style(task, output = false) {
    const rendererOptions = this.cache.rendererOptions.get(task.id);
    if (task.isSkipped()) {
      if (output || rendererOptions.collapseSkips) {
        return this.logger.icon("SKIPPED_WITH_COLLAPSE" /* SKIPPED_WITH_COLLAPSE */);
      } else if (rendererOptions.collapseSkips === false) {
        return this.logger.icon("SKIPPED_WITHOUT_COLLAPSE" /* SKIPPED_WITHOUT_COLLAPSE */);
      }
    }
    if (output) {
      if (this.isBottomBar(task)) {
        return this.logger.icon("OUTPUT_WITH_BOTTOMBAR" /* OUTPUT_WITH_BOTTOMBAR */);
      }
      return this.logger.icon("OUTPUT" /* OUTPUT */);
    }
    if (task.hasSubtasks()) {
      if (task.isStarted() || task.isPrompt() && rendererOptions.showSubtasks !== false && !task.subtasks.every((subtask) => !subtask.hasTitle())) {
        return this.logger.icon("PENDING" /* PENDING */);
      } else if (task.isCompleted() && task.subtasks.some((subtask) => subtask.hasFailed())) {
        return this.logger.icon("COMPLETED_WITH_FAILED_SUBTASKS" /* COMPLETED_WITH_FAILED_SUBTASKS */);
      } else if (task.hasFailed()) {
        return this.logger.icon("FAILED_WITH_SUBTASKS" /* FAILED_WITH_FAILED_SUBTASKS */);
      }
    }
    if (task.isStarted() || task.isPrompt()) {
      return this.logger.icon("PENDING" /* PENDING */, !this.options?.lazy && this.spinner.fetch());
    } else if (task.isCompleted()) {
      return this.logger.icon("COMPLETED" /* COMPLETED */);
    } else if (task.isRetrying()) {
      return this.logger.icon("RETRY" /* RETRY */, !this.options?.lazy && this.spinner.fetch());
    } else if (task.isRollingBack()) {
      return this.logger.icon("ROLLING_BACK" /* ROLLING_BACK */, !this.options?.lazy && this.spinner.fetch());
    } else if (task.hasRolledBack()) {
      return this.logger.icon("ROLLED_BACK" /* ROLLED_BACK */);
    } else if (task.hasFailed()) {
      return this.logger.icon("FAILED" /* FAILED */);
    } else if (task.isPaused()) {
      return this.logger.icon("PAUSED" /* PAUSED */);
    }
    return this.logger.icon("WAITING" /* WAITING */);
  }
  format(message, icon, level) {
    if (message.trim() === "") {
      return [];
    }
    if (icon) {
      message = icon + " " + message;
    }
    let parsed;
    const columns = (process.stdout.columns ?? 80) - level * this.options.indentation - 2;
    switch (this.options.formatOutput) {
      case "truncate":
        parsed = message.split(import_os3.EOL).map((s, i) => {
          return this.truncate(this.indent(s, i), columns);
        });
        break;
      case "wrap":
        parsed = this.wrap(message, columns, { hard: true }).split(import_os3.EOL).map((s, i) => this.indent(s, i));
        break;
      default:
        throw new ListrRendererError("Format option for the renderer is wrong.");
    }
    if (this.options.removeEmptyLines) {
      parsed = parsed.filter(Boolean);
    }
    return parsed.map((str) => indent(str, level * this.options.indentation));
  }
  renderer(tasks, level = 0) {
    return tasks.flatMap((task) => {
      if (!task.isEnabled()) {
        return [];
      }
      if (this.cache.output.has(task.id)) {
        return this.cache.output.get(task.id);
      }
      this.calculate(task);
      const rendererOptions = this.cache.rendererOptions.get(task.id);
      const rendererTaskOptions = this.cache.rendererTaskOptions.get(task.id);
      const output = [];
      if (task.isPrompt()) {
        if (this.activePrompt && this.activePrompt !== task.id) {
          throw new ListrRendererError("Only one prompt can be active at the given time, please re-evaluate your task design.");
        } else if (!this.activePrompt) {
          task.on("PROMPT" /* PROMPT */, (prompt) => {
            const cleansed = cleanseAnsi(prompt);
            if (cleansed) {
              this.prompt = cleansed;
            }
          });
          task.on("STATE" /* STATE */, (state) => {
            if (state === "PROMPT_COMPLETED" /* PROMPT_COMPLETED */ || task.hasFinalized() || task.hasReset()) {
              this.prompt = null;
              this.activePrompt = null;
              task.off("PROMPT" /* PROMPT */);
            }
          });
          this.activePrompt = task.id;
        }
      }
      if (task.hasTitle()) {
        if (!(tasks.some((task2) => task2.hasFailed()) && !task.hasFailed() && task.options.exitOnError !== false && !(task.isCompleted() || task.isSkipped()))) {
          if (task.hasFailed() && rendererOptions.collapseErrors) {
            output.push(...this.format(!task.hasSubtasks() && task.message.error && rendererOptions.showErrorMessage ? task.message.error : task.title, this.style(task), level));
          } else if (task.isSkipped() && rendererOptions.collapseSkips) {
            output.push(
              ...this.format(
                this.logger.suffix(task.message.skip && rendererOptions.showSkipMessage ? task.message.skip : task.title, {
                  field: "SKIPPED" /* SKIPPED */,
                  condition: rendererOptions.suffixSkips,
                  format: () => color.dim
                }),
                this.style(task),
                level
              )
            );
          } else if (task.isRetrying()) {
            output.push(
              ...this.format(
                this.logger.suffix(task.title, {
                  field: `${"RETRY" /* RETRY */}:${task.message.retry.count}`,
                  format: () => color.yellow,
                  condition: rendererOptions.suffixRetries
                }),
                this.style(task),
                level
              )
            );
          } else if (task.isCompleted() && task.hasTitle() && assertFunctionOrSelf(rendererTaskOptions.timer?.condition, task.message.duration)) {
            output.push(
              ...this.format(
                this.logger.suffix(task?.title, {
                  ...rendererTaskOptions.timer,
                  args: [task.message.duration]
                }),
                this.style(task),
                level
              )
            );
          } else if (task.isPaused()) {
            output.push(
              ...this.format(
                this.logger.suffix(task.title, {
                  ...rendererOptions.pausedTimer,
                  args: [task.message.paused - Date.now()]
                }),
                this.style(task),
                level
              )
            );
          } else {
            output.push(...this.format(task.title, this.style(task), level));
          }
        } else {
          output.push(...this.format(task.title, this.logger.icon("COMPLETED_WITH_SISTER_TASKS_FAILED" /* COMPLETED_WITH_FAILED_SISTER_TASKS */), level));
        }
      }
      if (!task.hasSubtasks() || !rendererOptions.showSubtasks) {
        if (task.hasFailed() && rendererOptions.collapseErrors === false && (rendererOptions.showErrorMessage || !rendererOptions.showSubtasks)) {
          output.push(...this.dump(task, level, "FAILED" /* FAILED */));
        } else if (task.isSkipped() && rendererOptions.collapseSkips === false && (rendererOptions.showSkipMessage || !rendererOptions.showSubtasks)) {
          output.push(...this.dump(task, level, "SKIPPED" /* SKIPPED */));
        }
      }
      if (task?.output) {
        if (this.isBottomBar(task)) {
          if (!this.bottom.has(task.id)) {
            this.bottom.set(task.id, new ProcessOutputBuffer({ limit: typeof rendererTaskOptions.bottomBar === "boolean" ? 1 : rendererTaskOptions.bottomBar }));
            task.on("OUTPUT" /* OUTPUT */, (output2) => {
              const data = this.dump(task, -1, "OUTPUT" /* OUTPUT */, output2);
              this.bottom.get(task.id).write(data.join(import_os3.EOL));
            });
          }
        } else if (task.isPending() || rendererTaskOptions.persistentOutput) {
          output.push(...this.dump(task, level));
        }
      }
      if (
        // check if renderer option is on first
        rendererOptions.showSubtasks !== false && // if it doesnt have subtasks no need to check
        task.hasSubtasks() && (task.isPending() || task.hasFinalized() && !task.hasTitle() || // have to be completed and have subtasks
        task.isCompleted() && rendererOptions.collapseSubtasks === false && !task.subtasks.some((subtask) => subtask.rendererOptions.collapseSubtasks === true) || // if any of the subtasks have the collapse option of
        task.subtasks.some((subtask) => subtask.rendererOptions.collapseSubtasks === false) || // if any of the subtasks has failed
        task.subtasks.some((subtask) => subtask.hasFailed()) || // if any of the subtasks rolled back
        task.subtasks.some((subtask) => subtask.hasRolledBack()))
      ) {
        const subtaskLevel = !task.hasTitle() ? level : level + 1;
        const subtaskRender = this.renderer(task.subtasks, subtaskLevel);
        output.push(...subtaskRender);
      }
      if (task.hasFinalized()) {
        if (!rendererTaskOptions.persistentOutput) {
          this.bottom.delete(task.id);
        }
      }
      if (task.isClosed()) {
        this.cache.output.set(task.id, output);
        this.reset(task);
      }
      return output;
    });
  }
  renderBottomBar() {
    if (this.bottom.size === 0) {
      return [];
    }
    return Array.from(this.bottom.values()).flatMap((output) => output.all).sort((a, b) => a.time - b.time).map((output) => output.entry);
  }
  renderPrompt() {
    if (!this.prompt) {
      return [];
    }
    return [this.prompt];
  }
  calculate(task) {
    if (this.cache.rendererOptions.has(task.id) && this.cache.rendererTaskOptions.has(task.id)) {
      return;
    }
    const rendererOptions = {
      ...this.options,
      ...task.rendererOptions
    };
    this.cache.rendererOptions.set(task.id, rendererOptions);
    this.cache.rendererTaskOptions.set(task.id, {
      ..._DefaultRenderer.rendererTaskOptions,
      timer: rendererOptions.timer,
      ...task.rendererTaskOptions
    });
  }
  reset(task) {
    this.cache.rendererOptions.delete(task.id);
    this.cache.rendererTaskOptions.delete(task.id);
  }
  dump(task, level, source = "OUTPUT" /* OUTPUT */, data) {
    if (!data) {
      switch (source) {
        case "OUTPUT" /* OUTPUT */:
          data = task.output;
          break;
        case "SKIPPED" /* SKIPPED */:
          data = task.message.skip;
          break;
        case "FAILED" /* FAILED */:
          data = task.message.error;
          break;
      }
    }
    if (task.hasTitle() && source === "FAILED" /* FAILED */ && data === task.title || typeof data !== "string") {
      return [];
    }
    if (source === "OUTPUT" /* OUTPUT */) {
      data = cleanseAnsi(data);
    }
    return this.format(data, this.style(task, true), level + 1);
  }
  indent(str, i) {
    return i > 0 ? indent(str.trim(), this.options.indentation) : str.trim();
  }
};
__name(_DefaultRenderer, "DefaultRenderer");
_DefaultRenderer.nonTTY = false;
_DefaultRenderer.rendererOptions = {
  indentation: 2,
  clearOutput: false,
  showSubtasks: true,
  collapseSubtasks: true,
  collapseSkips: true,
  showSkipMessage: true,
  suffixSkips: false,
  collapseErrors: true,
  showErrorMessage: true,
  suffixRetries: true,
  lazy: false,
  removeEmptyLines: true,
  formatOutput: "wrap",
  pausedTimer: {
    ...PRESET_TIMER,
    format: () => color.yellowBright
  }
};
var DefaultRenderer = _DefaultRenderer;

// src/renderer/silent/renderer.ts
var _SilentRenderer = class _SilentRenderer {
  constructor(tasks, options) {
    this.tasks = tasks;
    this.options = options;
  }
  render() {
    return;
  }
  end() {
    return;
  }
};
__name(_SilentRenderer, "SilentRenderer");
_SilentRenderer.nonTTY = true;
var SilentRenderer = _SilentRenderer;

// src/renderer/simple/renderer.ts
var _SimpleRenderer = class _SimpleRenderer {
  constructor(tasks, options) {
    this.tasks = tasks;
    this.options = options;
    this.cache = {
      rendererOptions: /* @__PURE__ */ new Map(),
      rendererTaskOptions: /* @__PURE__ */ new Map()
    };
    this.options = {
      ..._SimpleRenderer.rendererOptions,
      ...options,
      icon: {
        ...LISTR_LOGGER_STYLE.icon,
        ...options?.icon ?? {}
      },
      color: {
        ...LISTR_LOGGER_STYLE.color,
        ...options?.color ?? {}
      }
    };
    this.logger = this.options.logger ?? new ListrLogger({ useIcons: true, toStderr: LISTR_LOGGER_STDERR_LEVELS });
    this.logger.options.icon = this.options.icon;
    this.logger.options.color = this.options.color;
    if (this.options.timestamp) {
      this.logger.options.fields.prefix.unshift(this.options.timestamp);
    }
  }
  end() {
    this.logger.process.release();
  }
  render() {
    this.renderer(this.tasks);
  }
  renderer(tasks) {
    tasks.forEach((task) => {
      this.calculate(task);
      task.once("CLOSED" /* CLOSED */, () => {
        this.reset(task);
      });
      const rendererOptions = this.cache.rendererOptions.get(task.id);
      const rendererTaskOptions = this.cache.rendererTaskOptions.get(task.id);
      task.on("SUBTASK" /* SUBTASK */, (subtasks) => {
        this.renderer(subtasks);
      });
      task.on("STATE" /* STATE */, (state) => {
        if (!task.hasTitle()) {
          return;
        }
        if (state === "STARTED" /* STARTED */) {
          this.logger.log("STARTED" /* STARTED */, task.title);
        } else if (state === "COMPLETED" /* COMPLETED */) {
          const timer = rendererTaskOptions?.timer;
          this.logger.log(
            "COMPLETED" /* COMPLETED */,
            task.title,
            timer && {
              suffix: {
                ...timer,
                condition: !!task.message?.duration && timer.condition,
                args: [task.message.duration]
              }
            }
          );
        } else if (state === "PROMPT" /* PROMPT */) {
          this.logger.process.hijack();
          task.on("PROMPT" /* PROMPT */, (prompt) => {
            this.logger.process.toStderr(prompt, false);
          });
        } else if (state === "PROMPT_COMPLETED" /* PROMPT_COMPLETED */) {
          task.off("PROMPT" /* PROMPT */);
          this.logger.process.release();
        }
      });
      task.on("OUTPUT" /* OUTPUT */, (output) => {
        this.logger.log("OUTPUT" /* OUTPUT */, output);
      });
      task.on("MESSAGE" /* MESSAGE */, (message) => {
        if (message.error) {
          this.logger.log("FAILED" /* FAILED */, task.title, {
            suffix: {
              field: `${"FAILED" /* FAILED */}: ${message.error}`,
              format: () => color.red
            }
          });
        } else if (message.skip) {
          this.logger.log("SKIPPED" /* SKIPPED */, task.title, {
            suffix: {
              field: `${"SKIPPED" /* SKIPPED */}: ${message.skip}`,
              format: () => color.yellow
            }
          });
        } else if (message.rollback) {
          this.logger.log("ROLLBACK" /* ROLLBACK */, task.title, {
            suffix: {
              field: `${"ROLLBACK" /* ROLLBACK */}: ${message.rollback}`,
              format: () => color.red
            }
          });
        } else if (message.retry) {
          this.logger.log("RETRY" /* RETRY */, task.title, {
            suffix: {
              field: `${"RETRY" /* RETRY */}:${message.retry.count}`,
              format: () => color.red
            }
          });
        } else if (message.paused) {
          const timer = rendererOptions?.pausedTimer;
          this.logger.log(
            "PAUSED" /* PAUSED */,
            task.title,
            timer && {
              suffix: {
                ...timer,
                condition: !!message?.paused && timer.condition,
                args: [message.paused - Date.now()]
              }
            }
          );
        }
      });
    });
  }
  calculate(task) {
    if (this.cache.rendererOptions.has(task.id) && this.cache.rendererTaskOptions.has(task.id)) {
      return;
    }
    const rendererOptions = {
      ...this.options,
      ...task.rendererOptions
    };
    this.cache.rendererOptions.set(task.id, rendererOptions);
    this.cache.rendererTaskOptions.set(task.id, {
      ..._SimpleRenderer.rendererTaskOptions,
      timer: rendererOptions.timer,
      ...task.rendererTaskOptions
    });
  }
  reset(task) {
    this.cache.rendererOptions.delete(task.id);
    this.cache.rendererTaskOptions.delete(task.id);
  }
};
__name(_SimpleRenderer, "SimpleRenderer");
_SimpleRenderer.nonTTY = true;
_SimpleRenderer.rendererOptions = {
  pausedTimer: {
    ...PRESET_TIMER,
    field: (time) => `${"PAUSED" /* PAUSED */}:${time}`,
    format: () => color.yellowBright
  }
};
_SimpleRenderer.rendererTaskOptions = {};
var SimpleRenderer = _SimpleRenderer;

// src/renderer/test/serializer.ts
var _TestRendererSerializer = class _TestRendererSerializer {
  constructor(options) {
    this.options = options;
  }
  serialize(event, data, task) {
    return JSON.stringify(this.generate(event, data, task));
  }
  generate(event, data, task) {
    const output = {
      event,
      data
    };
    if (typeof this.options?.task !== "boolean") {
      const t = Object.fromEntries(
        this.options.task.map((entity) => {
          const property = task[entity];
          if (typeof property === "function") {
            return [entity, property.call(task)];
          }
          return [entity, property];
        })
      );
      if (Object.keys(task).length > 0) {
        output.task = t;
      }
    }
    return output;
  }
};
__name(_TestRendererSerializer, "TestRendererSerializer");
var TestRendererSerializer = _TestRendererSerializer;

// src/renderer/test/renderer.ts
var _TestRenderer = class _TestRenderer {
  constructor(tasks, options) {
    this.tasks = tasks;
    this.options = options;
    this.options = { ..._TestRenderer.rendererOptions, ...this.options };
    this.logger = this.options.logger ?? new ListrLogger({ useIcons: false });
    this.serializer = new TestRendererSerializer(this.options);
  }
  render() {
    this.renderer(this.tasks);
  }
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  end() {
  }
  // verbose renderer multi-level
  renderer(tasks) {
    tasks.forEach((task) => {
      if (this.options.subtasks) {
        task.on("SUBTASK" /* SUBTASK */, (subtasks) => {
          this.renderer(subtasks);
        });
      }
      if (this.options.state) {
        task.on("STATE" /* STATE */, (state) => {
          this.logger.toStdout(this.serializer.serialize("STATE" /* STATE */, state, task));
        });
      }
      if (this.options.output) {
        task.on("OUTPUT" /* OUTPUT */, (data) => {
          this.logger.toStdout(this.serializer.serialize("OUTPUT" /* OUTPUT */, data, task));
        });
      }
      if (this.options.prompt) {
        task.on("PROMPT" /* PROMPT */, (prompt) => {
          this.logger.toStdout(this.serializer.serialize("PROMPT" /* PROMPT */, prompt, task));
        });
      }
      if (this.options.title) {
        task.on("TITLE" /* TITLE */, (title) => {
          this.logger.toStdout(this.serializer.serialize("TITLE" /* TITLE */, title, task));
        });
      }
      task.on("MESSAGE" /* MESSAGE */, (message) => {
        const parsed = Object.fromEntries(
          Object.entries(message).map(([key, value]) => {
            if (this.options.messages.includes(key)) {
              return [key, value];
            }
          }).filter(Boolean)
        );
        if (Object.keys(parsed).length > 0) {
          const output = this.serializer.serialize("MESSAGE" /* MESSAGE */, parsed, task);
          if (this.options.messagesToStderr.some((state) => Object.keys(parsed).includes(state))) {
            this.logger.toStderr(output);
          } else {
            this.logger.toStdout(output);
          }
        }
      });
    });
  }
};
__name(_TestRenderer, "TestRenderer");
_TestRenderer.nonTTY = true;
_TestRenderer.rendererOptions = {
  subtasks: true,
  state: Object.values(ListrTaskState),
  output: true,
  prompt: true,
  title: true,
  messages: ["skip", "error", "retry", "rollback", "paused"],
  messagesToStderr: ["error", "rollback", "retry"],
  task: [
    "hasRolledBack",
    "isRollingBack",
    "isCompleted",
    "isSkipped",
    "hasFinalized",
    "hasSubtasks",
    "title",
    "hasReset",
    "hasTitle",
    "isPrompt",
    "isPaused",
    "isPending",
    "isSkipped",
    "isStarted",
    "hasFailed",
    "isEnabled",
    "isRetrying",
    "path"
  ]
};
var TestRenderer = _TestRenderer;

// src/renderer/verbose/renderer.ts
var _VerboseRenderer = class _VerboseRenderer {
  constructor(tasks, options) {
    this.tasks = tasks;
    this.options = options;
    this.cache = {
      rendererOptions: /* @__PURE__ */ new Map(),
      rendererTaskOptions: /* @__PURE__ */ new Map()
    };
    this.options = {
      ..._VerboseRenderer.rendererOptions,
      ...this.options,
      icon: {
        ...LISTR_LOGGER_STYLE.icon,
        ...options?.icon ?? {}
      },
      color: {
        ...LISTR_LOGGER_STYLE.color,
        ...options?.color ?? {}
      }
    };
    this.logger = this.options.logger ?? new ListrLogger({ useIcons: false, toStderr: LISTR_LOGGER_STDERR_LEVELS });
    this.logger.options.icon = this.options.icon;
    this.logger.options.color = this.options.color;
    if (this.options.timestamp) {
      this.logger.options.fields.prefix.unshift(this.options.timestamp);
    }
  }
  render() {
    this.renderer(this.tasks);
  }
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  end() {
  }
  renderer(tasks) {
    tasks.forEach((task) => {
      this.calculate(task);
      task.once("CLOSED" /* CLOSED */, () => {
        this.reset(task);
      });
      const rendererOptions = this.cache.rendererOptions.get(task.id);
      const rendererTaskOptions = this.cache.rendererTaskOptions.get(task.id);
      task.on("SUBTASK" /* SUBTASK */, (subtasks) => {
        this.renderer(subtasks);
      });
      task.on("STATE" /* STATE */, (state) => {
        if (!task.hasTitle()) {
          return;
        }
        if (state === "STARTED" /* STARTED */) {
          this.logger.log("STARTED" /* STARTED */, task.title);
        } else if (state === "COMPLETED" /* COMPLETED */) {
          const timer = rendererTaskOptions.timer;
          this.logger.log(
            "COMPLETED" /* COMPLETED */,
            task.title,
            timer && {
              suffix: {
                ...timer,
                condition: !!task.message?.duration && timer.condition,
                args: [task.message.duration]
              }
            }
          );
        }
      });
      task.on("OUTPUT" /* OUTPUT */, (data) => {
        this.logger.log("OUTPUT" /* OUTPUT */, data);
      });
      task.on("PROMPT" /* PROMPT */, (prompt) => {
        const cleansed = cleanseAnsi(prompt);
        if (cleansed) {
          this.logger.log("PROMPT" /* PROMPT */, cleansed);
        }
      });
      if (this.options?.logTitleChange !== false) {
        task.on("TITLE" /* TITLE */, (title) => {
          this.logger.log("TITLE" /* TITLE */, title);
        });
      }
      task.on("MESSAGE" /* MESSAGE */, (message) => {
        if (message?.error) {
          this.logger.log("FAILED" /* FAILED */, message.error);
        } else if (message?.skip) {
          this.logger.log("SKIPPED" /* SKIPPED */, message.skip);
        } else if (message?.rollback) {
          this.logger.log("ROLLBACK" /* ROLLBACK */, message.rollback);
        } else if (message?.retry) {
          this.logger.log("RETRY" /* RETRY */, task.title, { suffix: message.retry.count.toString() });
        } else if (message?.paused) {
          const timer = rendererOptions?.pausedTimer;
          this.logger.log(
            "PAUSED" /* PAUSED */,
            task.title,
            timer && {
              suffix: {
                ...timer,
                condition: !!message?.paused && timer.condition,
                args: [message.paused - Date.now()]
              }
            }
          );
        }
      });
    });
  }
  calculate(task) {
    if (this.cache.rendererOptions.has(task.id) && this.cache.rendererTaskOptions.has(task.id)) {
      return;
    }
    const rendererOptions = {
      ...this.options,
      ...task.rendererOptions
    };
    this.cache.rendererOptions.set(task.id, rendererOptions);
    this.cache.rendererTaskOptions.set(task.id, {
      ..._VerboseRenderer.rendererTaskOptions,
      timer: rendererOptions.timer,
      ...task.rendererTaskOptions
    });
  }
  reset(task) {
    this.cache.rendererOptions.delete(task.id);
    this.cache.rendererTaskOptions.delete(task.id);
  }
};
__name(_VerboseRenderer, "VerboseRenderer");
_VerboseRenderer.nonTTY = true;
_VerboseRenderer.rendererOptions = {
  logTitleChange: false,
  pausedTimer: {
    ...PRESET_TIMER,
    format: () => color.yellowBright
  }
};
var VerboseRenderer = _VerboseRenderer;

// src/utils/ui/renderer.ts
var RENDERERS = {
  default: DefaultRenderer,
  simple: SimpleRenderer,
  verbose: VerboseRenderer,
  test: TestRenderer,
  silent: SilentRenderer
};
function isRendererSupported(renderer) {
  return process.stdout.isTTY === true || renderer.nonTTY === true;
}
__name(isRendererSupported, "isRendererSupported");
function getRendererClass(renderer) {
  if (typeof renderer === "string") {
    return RENDERERS[renderer] ?? RENDERERS.default;
  }
  return typeof renderer === "function" ? renderer : RENDERERS.default;
}
__name(getRendererClass, "getRendererClass");
function getRenderer(options) {
  if (assertFunctionOrSelf(options?.silentRendererCondition)) {
    return { renderer: getRendererClass("silent") };
  }
  const r = { renderer: getRendererClass(options.renderer), options: options.rendererOptions };
  if (!isRendererSupported(r.renderer) || assertFunctionOrSelf(options?.fallbackRendererCondition)) {
    return { renderer: getRendererClass(options.fallbackRenderer), options: options.fallbackRendererOptions };
  }
  return r;
}
__name(getRenderer, "getRenderer");

// src/utils/assert.ts
function assertFunctionOrSelf(functionOrSelf, ...args) {
  if (typeof functionOrSelf === "function") {
    return functionOrSelf(...args);
  } else {
    return functionOrSelf;
  }
}
__name(assertFunctionOrSelf, "assertFunctionOrSelf");

// src/utils/clone.ts
var import_rfdc = __toESM(require("rfdc"), 1);
var clone = (0, import_rfdc.default)({ circles: true });
function cloneObject(obj) {
  return clone(obj);
}
__name(cloneObject, "cloneObject");

// src/utils/concurrency.ts
var _Concurrency = class _Concurrency {
  constructor(options) {
    this.concurrency = options.concurrency;
    this.count = 0;
    this.queue = /* @__PURE__ */ new Set();
  }
  add(fn) {
    if (this.count < this.concurrency) {
      return this.run(fn);
    }
    return new Promise((resolve) => {
      const callback = /* @__PURE__ */ __name(() => resolve(this.run(fn)), "callback");
      this.queue.add(callback);
    });
  }
  flush() {
    for (const callback of this.queue) {
      if (this.count >= this.concurrency) {
        break;
      }
      this.queue.delete(callback);
      callback();
    }
  }
  run(fn) {
    this.count++;
    const promise = fn();
    const cleanup = /* @__PURE__ */ __name(() => {
      this.count--;
      this.flush();
    }, "cleanup");
    promise.then(cleanup, () => {
      this.queue.clear();
    });
    return promise;
  }
};
__name(_Concurrency, "Concurrency");
var Concurrency = _Concurrency;

// src/utils/delay.ts
function delay(time) {
  return new Promise((resolve) => {
    setTimeout(resolve, time);
  });
}
__name(delay, "delay");

// src/interfaces/listr-error.interface.ts
var _ListrError = class _ListrError extends Error {
  constructor(error, type, task) {
    super(error.message);
    this.error = error;
    this.type = type;
    this.task = task;
    this.name = "ListrError";
    this.path = task.path;
    if (task?.options.collectErrors === "full") {
      this.task = cloneObject(task);
      this.ctx = cloneObject(task.listr.ctx);
    }
    this.stack = error?.stack;
  }
};
__name(_ListrError, "ListrError");
var ListrError = _ListrError;

// src/interfaces/listr-renderer-error.interface.ts
var _ListrRendererError = class _ListrRendererError extends Error {
};
__name(_ListrRendererError, "ListrRendererError");
var ListrRendererError = _ListrRendererError;

// src/interfaces/prompt-error.interface.ts
var _PromptError = class _PromptError extends Error {
};
__name(_PromptError, "PromptError");
var PromptError = _PromptError;

// src/lib/task-wrapper.ts
var _TaskWrapper = class _TaskWrapper {
  constructor(task, options) {
    this.task = task;
    this.options = options;
  }
  get title() {
    return this.task.title;
  }
  /**
   * Title of the current task.
   *
   * @see {@link https://listr2.kilic.dev/task/title.html}
   */
  set title(title) {
    title = Array.isArray(title) ? title : [title];
    this.task.title$ = splat(title.shift(), ...title);
  }
  get output() {
    return this.task.output;
  }
  /**
   * Send output from the current task to the renderer.
   *
   * @see {@link https://listr2.kilic.dev/task/output.html}
   */
  set output(output) {
    output = Array.isArray(output) ? output : [output];
    this.task.output$ = splat(output.shift(), ...output);
  }
  /** Send an output to the output channel as prompt. */
  set promptOutput(output) {
    this.task.promptOutput$ = output;
  }
  /**
   * Creates a new set of Listr subtasks.
   *
   * @see {@link https://listr2.kilic.dev/task/subtasks.html}
   */
  newListr(task, options) {
    let tasks;
    if (typeof task === "function") {
      tasks = task(this);
    } else {
      tasks = task;
    }
    return new Listr(tasks, options, this.task);
  }
  /**
   * Report an error that has to be collected and handled.
   *
   * @see {@link https://listr2.kilic.dev/task/error-handling.html}
   */
  report(error, type) {
    if (this.task.options.collectErrors !== false) {
      this.task.listr.errors.push(new ListrError(error, type, this.task));
    }
    this.task.message$ = { error: error.message ?? this.task?.title };
  }
  /**
   * Skip the current task.
   *
   * @see {@link https://listr2.kilic.dev/task/skip.html}
   */
  skip(message, ...metadata) {
    this.task.state$ = "SKIPPED" /* SKIPPED */;
    if (message) {
      this.task.message$ = { skip: message ? splat(message, ...metadata) : this.task?.title };
    }
  }
  /**
   * Check whether this task is currently in a retry state.
   *
   * @see {@link https://listr2.kilic.dev/task/retry.html}
   */
  isRetrying() {
    return this.task.isRetrying() ? this.task.retry : { count: 0 };
  }
  /**
   * Create a new prompt for getting user input through `enquirer`.
   *
   * - `enquirer` is a optional peer dependency and has to be already installed separately.
   *
   * @see {@link https://listr2.kilic.dev/task/prompt.html}
   */
  async prompt(options) {
    return createPrompt.bind(this)(options, { ...this.options?.injectWrapper });
  }
  /* istanbul ignore next */
  /**
   * Cancel the current active prompt, if there is any.
   *
   * @see {@link https://listr2.kilic.dev/task/prompt.html}
   */
  cancelPrompt(options) {
    if (!this.task.prompt || this.task.prompt instanceof PromptError) {
      return;
    }
    if (options?.throw) {
      this.task.prompt.cancel();
    } else {
      this.task.prompt.submit();
    }
  }
  /**
   * Generates a fake stdout for your use case, where it will be tunnelled through Listr to handle the rendering process.
   *
   * @see {@link https://listr2.kilic.dev/renderer/process-output.html}
   */
  stdout(type) {
    return createWritable((chunk) => {
      switch (type) {
        case "PROMPT" /* PROMPT */:
          this.promptOutput = chunk.toString();
          break;
        default:
          this.output = chunk.toString();
      }
    });
  }
  /** Run this task. */
  run(ctx) {
    return this.task.run(ctx, this);
  }
};
__name(_TaskWrapper, "TaskWrapper");
var TaskWrapper = _TaskWrapper;

// src/lib/task.ts
var import_crypto = require("crypto");
var import_stream2 = require("stream");

// src/lib/listr-task-event-manager.ts
var _ListrTaskEventManager = class _ListrTaskEventManager extends EventManager {
};
__name(_ListrTaskEventManager, "ListrTaskEventManager");
var ListrTaskEventManager = _ListrTaskEventManager;

// src/lib/task.ts
var _Task = class _Task extends ListrTaskEventManager {
  constructor(listr, task, options, rendererOptions) {
    super();
    this.listr = listr;
    this.task = task;
    this.options = options;
    this.rendererOptions = rendererOptions;
    /** Unique id per task, can be used for identifying a Task. */
    this.id = (0, import_crypto.randomUUID)();
    /** The current state of the task. */
    this.state = "WAITING" /* WAITING */;
    /**
     * A channel for messages.
     *
     * This requires a separate channel for messages like error, skip or runtime messages to further utilize in the renderers.
     */
    this.message = {};
    if (task.title) {
      const title = Array.isArray(task?.title) ? task.title : [task.title];
      this.title = splat(title.shift(), ...title);
      this.initialTitle = this.title;
    }
    this.taskFn = task.task;
    this.parent = listr.parentTask;
    this.rendererTaskOptions = task.options;
  }
  /**
   * Update the current state of the Task and emit the neccassary events.
   */
  set state$(state) {
    this.state = state;
    this.emit("STATE" /* STATE */, state);
    if (this.hasSubtasks() && this.hasFailed()) {
      for (const subtask of this.subtasks) {
        if (subtask.state === "STARTED" /* STARTED */) {
          subtask.state$ = "FAILED" /* FAILED */;
        }
      }
    }
    this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
  }
  /**
   * Update the current output of the Task and emit the neccassary events.
   */
  set output$(data) {
    this.output = data;
    this.emit("OUTPUT" /* OUTPUT */, data);
    this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
  }
  /**
   * Update the current prompt output of the Task and emit the neccassary events.
   */
  set promptOutput$(data) {
    this.emit("PROMPT" /* PROMPT */, data);
    if (cleanseAnsi(data)) {
      this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
    }
  }
  /**
   * Update or extend the current message of the Task and emit the neccassary events.
   */
  set message$(data) {
    this.message = { ...this.message, ...data };
    this.emit("MESSAGE" /* MESSAGE */, data);
    this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
  }
  /**
   * Update the current title of the Task and emit the neccassary events.
   */
  set title$(title) {
    this.title = title;
    this.emit("TITLE" /* TITLE */, title);
    this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
  }
  /**
   * Current task path in the hierarchy.
   */
  get path() {
    return [...this.listr.path, this.initialTitle];
  }
  /**
   * Checks whether the current task with the given context should be set as enabled.
   */
  async check(ctx) {
    if (this.state === "WAITING" /* WAITING */) {
      this.enabled = await assertFunctionOrSelf(this.task?.enabled ?? true, ctx);
      this.emit("ENABLED" /* ENABLED */, this.enabled);
      this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
    }
    return this.enabled;
  }
  /** Returns whether this task has subtasks. */
  hasSubtasks() {
    return this.subtasks?.length > 0;
  }
  /** Returns whether this task is finalized in someform. */
  hasFinalized() {
    return this.isCompleted() || this.hasFailed() || this.isSkipped() || this.hasRolledBack();
  }
  /** Returns whether this task is in progress. */
  isPending() {
    return this.isStarted() || this.isPrompt() || this.hasReset();
  }
  /** Returns whether this task has started. */
  isStarted() {
    return this.state === "STARTED" /* STARTED */;
  }
  /** Returns whether this task is skipped. */
  isSkipped() {
    return this.state === "SKIPPED" /* SKIPPED */;
  }
  /** Returns whether this task has been completed. */
  isCompleted() {
    return this.state === "COMPLETED" /* COMPLETED */;
  }
  /** Returns whether this task has been failed. */
  hasFailed() {
    return this.state === "FAILED" /* FAILED */;
  }
  /** Returns whether this task has an active rollback task going on. */
  isRollingBack() {
    return this.state === "ROLLING_BACK" /* ROLLING_BACK */;
  }
  /** Returns whether the rollback action was successful. */
  hasRolledBack() {
    return this.state === "ROLLED_BACK" /* ROLLED_BACK */;
  }
  /** Returns whether this task has an actively retrying task going on. */
  isRetrying() {
    return this.state === "RETRY" /* RETRY */;
  }
  /** Returns whether this task has some kind of reset like retry and rollback going on. */
  hasReset() {
    return this.state === "RETRY" /* RETRY */ || this.state === "ROLLING_BACK" /* ROLLING_BACK */;
  }
  /** Returns whether enabled function resolves to true. */
  isEnabled() {
    return this.enabled;
  }
  /** Returns whether this task actually has a title. */
  hasTitle() {
    return typeof this?.title === "string";
  }
  /** Returns whether this task has a prompt inside. */
  isPrompt() {
    return this.state === "PROMPT" /* PROMPT */ || this.state === "PROMPT_COMPLETED" /* PROMPT_COMPLETED */;
  }
  /** Returns whether this task is currently paused. */
  isPaused() {
    return this.state === "PAUSED" /* PAUSED */;
  }
  /** Returns whether this task is closed. */
  isClosed() {
    return this.closed;
  }
  /** Pause the given task for certain time. */
  async pause(time) {
    const state = this.state;
    this.state$ = "PAUSED" /* PAUSED */;
    this.message$ = {
      paused: Date.now() + time
    };
    await delay(time);
    this.state$ = state;
    this.message$ = {
      paused: null
    };
  }
  /** Run the current task. */
  async run(context, wrapper) {
    const handleResult = /* @__PURE__ */ __name((result) => {
      if (result instanceof Listr) {
        result.options = { ...this.options, ...result.options };
        result.rendererClass = getRendererClass("silent");
        this.subtasks = result.tasks;
        result.errors = this.listr.errors;
        this.emit("SUBTASK" /* SUBTASK */, this.subtasks);
        result = result.run(context);
      } else if (result instanceof Promise) {
        result = result.then(handleResult);
      } else if (result instanceof import_stream2.Readable) {
        result = new Promise((resolve, reject) => {
          result.on("data", (data) => {
            this.output$ = data.toString();
          });
          result.on("error", (error) => reject(error));
          result.on("end", () => resolve(null));
        });
      } else if (isObservable(result)) {
        result = new Promise((resolve, reject) => {
          result.subscribe({
            next: (data) => {
              this.output$ = data;
            },
            error: reject,
            complete: resolve
          });
        });
      }
      return result;
    }, "handleResult");
    const startTime = Date.now();
    this.state$ = "STARTED" /* STARTED */;
    const skipped = await assertFunctionOrSelf(this.task?.skip ?? false, context);
    if (skipped) {
      if (typeof skipped === "string") {
        this.message$ = { skip: skipped };
      } else if (this.hasTitle()) {
        this.message$ = { skip: this.title };
      } else {
        this.message$ = { skip: "Skipped task without a title." };
      }
      this.state$ = "SKIPPED" /* SKIPPED */;
      return;
    }
    try {
      const retryCount = typeof this.task?.retry === "number" && this.task.retry > 0 ? this.task.retry + 1 : typeof this.task?.retry === "object" && this.task.retry.tries > 0 ? this.task.retry.tries + 1 : 1;
      const retryDelay = typeof this.task.retry === "object" && this.task.retry.delay;
      for (let retries = 1; retries <= retryCount; retries++) {
        try {
          await handleResult(this.taskFn(context, wrapper));
          break;
        } catch (err) {
          if (retries !== retryCount) {
            this.retry = { count: retries, error: err };
            this.message$ = { retry: this.retry };
            this.title$ = this.initialTitle;
            this.output = void 0;
            wrapper.report(err, "WILL_RETRY" /* WILL_RETRY */);
            this.state$ = "RETRY" /* RETRY */;
            if (retryDelay) {
              await this.pause(retryDelay);
            }
          } else {
            throw err;
          }
        }
      }
      if (this.isStarted() || this.isRetrying()) {
        this.message$ = { duration: Date.now() - startTime };
        this.state$ = "COMPLETED" /* COMPLETED */;
      }
    } catch (error) {
      if (this.prompt instanceof PromptError) {
        error = this.prompt;
      }
      if (this.task?.rollback) {
        wrapper.report(error, "WILL_ROLLBACK" /* WILL_ROLLBACK */);
        try {
          this.state$ = "ROLLING_BACK" /* ROLLING_BACK */;
          await this.task.rollback(context, wrapper);
          this.message$ = { rollback: this.title };
          this.state$ = "ROLLED_BACK" /* ROLLED_BACK */;
        } catch (err) {
          this.state$ = "FAILED" /* FAILED */;
          wrapper.report(err, "HAS_FAILED_TO_ROLLBACK" /* HAS_FAILED_TO_ROLLBACK */);
          this.close();
          throw err;
        }
        if (this.listr.options?.exitAfterRollback !== false) {
          this.close();
          throw error;
        }
      } else {
        this.state$ = "FAILED" /* FAILED */;
        if (this.listr.options.exitOnError !== false && await assertFunctionOrSelf(this.task?.exitOnError, context) !== false) {
          wrapper.report(error, "HAS_FAILED" /* HAS_FAILED */);
          this.close();
          throw error;
        } else if (!this.hasSubtasks()) {
          wrapper.report(error, "HAS_FAILED_WITHOUT_ERROR" /* HAS_FAILED_WITHOUT_ERROR */);
        }
      }
    } finally {
      this.close();
    }
  }
  close() {
    this.emit("CLOSED" /* CLOSED */);
    this.listr.events.emit("SHOUD_REFRESH_RENDER" /* SHOULD_REFRESH_RENDER */);
    this.complete();
  }
};
__name(_Task, "Task");
var Task = _Task;

// src/lib/listr-event-manager.ts
var _ListrEventManager = class _ListrEventManager extends EventManager {
};
__name(_ListrEventManager, "ListrEventManager");
var ListrEventManager = _ListrEventManager;

// src/listr.ts
var _Listr = class _Listr {
  constructor(task, options, parentTask) {
    this.task = task;
    this.options = options;
    this.parentTask = parentTask;
    this.tasks = [];
    this.errors = [];
    this.path = [];
    this.options = {
      concurrent: false,
      renderer: "default",
      fallbackRenderer: "simple",
      exitOnError: true,
      exitAfterRollback: true,
      collectErrors: false,
      registerSignalListeners: true,
      ...this.parentTask?.options ?? {},
      ...options
    };
    if (this.options.concurrent === true) {
      this.options.concurrent = Infinity;
    } else if (typeof this.options.concurrent !== "number") {
      this.options.concurrent = 1;
    }
    this.concurrency = new Concurrency({ concurrency: this.options.concurrent });
    if (parentTask) {
      this.path = [...parentTask.listr.path, parentTask.title];
      this.errors = parentTask.listr.errors;
    }
    if (this.parentTask?.listr.events instanceof ListrEventManager) {
      this.events = this.parentTask.listr.events;
    } else {
      this.events = new ListrEventManager();
    }
    const renderer = getRenderer({
      renderer: this.options.renderer,
      rendererOptions: this.options.rendererOptions,
      fallbackRenderer: this.options.fallbackRenderer,
      fallbackRendererOptions: this.options.fallbackRendererOptions,
      fallbackRendererCondition: this.options?.fallbackRendererCondition,
      silentRendererCondition: this.options?.silentRendererCondition
    });
    this.rendererClass = renderer.renderer;
    this.rendererClassOptions = renderer.options;
    this.add(task ?? []);
    if (this.options.registerSignalListeners) {
      process.once("SIGINT", () => {
        this.tasks.forEach(async (task2) => {
          if (task2.isPending()) {
            task2.state$ = "FAILED" /* FAILED */;
          }
        });
        this.renderer.end(new Error("Interrupted."));
        process.exit(127);
      }).setMaxListeners(0);
    }
    if (this.options?.disableColor) {
      process.env["LISTR_DISABLE_COLOR" /* DISABLE_COLOR */] = "1";
    } else if (this.options?.forceColor) {
      process.env["FORCE_COLOR" /* FORCE_COLOR */] = "1";
    }
    if (this.options?.forceTTY) {
      process.stdout.isTTY = true;
      process.stderr.isTTY = true;
    }
    if (this.options?.forceUnicode) {
      process.env["LISTR_FORCE_UNICODE" /* FORCE_UNICODE */] = "1";
    }
  }
  add(tasks) {
    this.tasks.push(...this.generate(tasks));
  }
  async run(context) {
    if (!this.renderer) {
      this.renderer = new this.rendererClass(this.tasks, this.rendererClassOptions, this.events);
    }
    await this.renderer.render();
    this.ctx = this.options?.ctx ?? context ?? {};
    await Promise.all(this.tasks.map((task) => task.check(this.ctx)));
    try {
      await Promise.all(this.tasks.map((task) => this.concurrency.add(() => this.runTask(task))));
      this.renderer.end();
    } catch (err) {
      if (this.options.exitOnError !== false) {
        this.renderer.end(err);
        throw err;
      }
    }
    return this.ctx;
  }
  generate(tasks) {
    tasks = Array.isArray(tasks) ? tasks : [tasks];
    return tasks.map((task) => new Task(this, task, this.options, { ...this.rendererClassOptions }));
  }
  async runTask(task) {
    if (!await task.check(this.ctx)) {
      return;
    }
    return new TaskWrapper(task, this.options).run(this.ctx);
  }
};
__name(_Listr, "Listr");
var Listr = _Listr;

// src/manager.ts
var _Manager = class _Manager {
  constructor(options) {
    this.options = options;
    this.errors = [];
    this.tasks = [];
  }
  get ctx() {
    return this.options.ctx;
  }
  set ctx(ctx) {
    this.options.ctx = ctx;
  }
  add(tasks, options) {
    options = { ...this.options, ...options };
    this.tasks = [...this.tasks, this.indent(tasks, options)];
  }
  async runAll(options) {
    options = { ...this.options, ...options };
    const tasks = [...this.tasks];
    this.tasks = [];
    const ctx = await this.run(tasks, options);
    return ctx;
  }
  newListr(tasks, options) {
    return new Listr(tasks, options);
  }
  indent(tasks, options, taskOptions) {
    options = { ...this.options, ...options };
    if (typeof tasks === "function") {
      return {
        ...taskOptions,
        task: (ctx) => this.newListr(tasks(ctx), options)
      };
    }
    return {
      ...taskOptions,
      task: () => this.newListr(tasks, options)
    };
  }
  async run(tasks, options) {
    options = { ...this.options, ...options };
    const task = this.newListr(tasks, options);
    const ctx = await task.run();
    this.errors.push(...task.errors);
    return ctx;
  }
};
__name(_Manager, "Manager");
var Manager = _Manager;
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  ANSI_ESCAPE,
  ANSI_ESCAPE_CODES,
  BaseEventMap,
  Concurrency,
  DefaultRenderer,
  EventManager,
  LISTR_DEFAULT_RENDERER_STYLE,
  LISTR_LOGGER_STDERR_LEVELS,
  LISTR_LOGGER_STYLE,
  Listr,
  ListrDefaultRendererLogLevels,
  ListrEnvironmentVariables,
  ListrError,
  ListrErrorTypes,
  ListrEventManager,
  ListrEventType,
  ListrLogLevels,
  ListrLogger,
  ListrRendererError,
  ListrTaskEventManager,
  ListrTaskEventType,
  ListrTaskState,
  Manager,
  PRESET_TIMER,
  PRESET_TIMESTAMP,
  ProcessOutput,
  ProcessOutputBuffer,
  ProcessOutputStream,
  PromptError,
  SilentRenderer,
  SimpleRenderer,
  Spinner,
  TestRenderer,
  TestRendererSerializer,
  VerboseRenderer,
  assertFunctionOrSelf,
  cleanseAnsi,
  cloneObject,
  color,
  createPrompt,
  createWritable,
  delay,
  figures,
  getRenderer,
  getRendererClass,
  indent,
  isObservable,
  isUnicodeSupported,
  parseTimer,
  parseTimestamp,
  splat
});
