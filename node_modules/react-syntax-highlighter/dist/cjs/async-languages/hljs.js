"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _typeof2 = _interopRequireDefault(require("@babel/runtime/helpers/typeof"));

var _createLanguageAsyncLoader = _interopRequireDefault(require("./create-language-async-loader"));

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || (0, _typeof2["default"])(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

var _default = {
  oneC: (0, _createLanguageAsyncLoader["default"])("oneC", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/1c"));
    });
  }),
  abnf: (0, _createLanguageAsyncLoader["default"])("abnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/abnf"));
    });
  }),
  accesslog: (0, _createLanguageAsyncLoader["default"])("accesslog", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/accesslog"));
    });
  }),
  actionscript: (0, _createLanguageAsyncLoader["default"])("actionscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/actionscript"));
    });
  }),
  ada: (0, _createLanguageAsyncLoader["default"])("ada", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ada"));
    });
  }),
  angelscript: (0, _createLanguageAsyncLoader["default"])("angelscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/angelscript"));
    });
  }),
  apache: (0, _createLanguageAsyncLoader["default"])("apache", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/apache"));
    });
  }),
  applescript: (0, _createLanguageAsyncLoader["default"])("applescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/applescript"));
    });
  }),
  arcade: (0, _createLanguageAsyncLoader["default"])("arcade", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/arcade"));
    });
  }),
  arduino: (0, _createLanguageAsyncLoader["default"])("arduino", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/arduino"));
    });
  }),
  armasm: (0, _createLanguageAsyncLoader["default"])("armasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/armasm"));
    });
  }),
  asciidoc: (0, _createLanguageAsyncLoader["default"])("asciidoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/asciidoc"));
    });
  }),
  aspectj: (0, _createLanguageAsyncLoader["default"])("aspectj", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/aspectj"));
    });
  }),
  autohotkey: (0, _createLanguageAsyncLoader["default"])("autohotkey", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/autohotkey"));
    });
  }),
  autoit: (0, _createLanguageAsyncLoader["default"])("autoit", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/autoit"));
    });
  }),
  avrasm: (0, _createLanguageAsyncLoader["default"])("avrasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/avrasm"));
    });
  }),
  awk: (0, _createLanguageAsyncLoader["default"])("awk", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/awk"));
    });
  }),
  axapta: (0, _createLanguageAsyncLoader["default"])("axapta", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/axapta"));
    });
  }),
  bash: (0, _createLanguageAsyncLoader["default"])("bash", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/bash"));
    });
  }),
  basic: (0, _createLanguageAsyncLoader["default"])("basic", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/basic"));
    });
  }),
  bnf: (0, _createLanguageAsyncLoader["default"])("bnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/bnf"));
    });
  }),
  brainfuck: (0, _createLanguageAsyncLoader["default"])("brainfuck", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/brainfuck"));
    });
  }),
  cLike: (0, _createLanguageAsyncLoader["default"])("cLike", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/c-like"));
    });
  }),
  c: (0, _createLanguageAsyncLoader["default"])("c", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/c"));
    });
  }),
  cal: (0, _createLanguageAsyncLoader["default"])("cal", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/cal"));
    });
  }),
  capnproto: (0, _createLanguageAsyncLoader["default"])("capnproto", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/capnproto"));
    });
  }),
  ceylon: (0, _createLanguageAsyncLoader["default"])("ceylon", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ceylon"));
    });
  }),
  clean: (0, _createLanguageAsyncLoader["default"])("clean", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/clean"));
    });
  }),
  clojureRepl: (0, _createLanguageAsyncLoader["default"])("clojureRepl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/clojure-repl"));
    });
  }),
  clojure: (0, _createLanguageAsyncLoader["default"])("clojure", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/clojure"));
    });
  }),
  cmake: (0, _createLanguageAsyncLoader["default"])("cmake", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/cmake"));
    });
  }),
  coffeescript: (0, _createLanguageAsyncLoader["default"])("coffeescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/coffeescript"));
    });
  }),
  coq: (0, _createLanguageAsyncLoader["default"])("coq", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/coq"));
    });
  }),
  cos: (0, _createLanguageAsyncLoader["default"])("cos", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/cos"));
    });
  }),
  cpp: (0, _createLanguageAsyncLoader["default"])("cpp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/cpp"));
    });
  }),
  crmsh: (0, _createLanguageAsyncLoader["default"])("crmsh", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/crmsh"));
    });
  }),
  crystal: (0, _createLanguageAsyncLoader["default"])("crystal", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/crystal"));
    });
  }),
  csharp: (0, _createLanguageAsyncLoader["default"])("csharp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/csharp"));
    });
  }),
  csp: (0, _createLanguageAsyncLoader["default"])("csp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/csp"));
    });
  }),
  css: (0, _createLanguageAsyncLoader["default"])("css", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/css"));
    });
  }),
  d: (0, _createLanguageAsyncLoader["default"])("d", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/d"));
    });
  }),
  dart: (0, _createLanguageAsyncLoader["default"])("dart", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dart"));
    });
  }),
  delphi: (0, _createLanguageAsyncLoader["default"])("delphi", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/delphi"));
    });
  }),
  diff: (0, _createLanguageAsyncLoader["default"])("diff", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/diff"));
    });
  }),
  django: (0, _createLanguageAsyncLoader["default"])("django", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/django"));
    });
  }),
  dns: (0, _createLanguageAsyncLoader["default"])("dns", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dns"));
    });
  }),
  dockerfile: (0, _createLanguageAsyncLoader["default"])("dockerfile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dockerfile"));
    });
  }),
  dos: (0, _createLanguageAsyncLoader["default"])("dos", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dos"));
    });
  }),
  dsconfig: (0, _createLanguageAsyncLoader["default"])("dsconfig", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dsconfig"));
    });
  }),
  dts: (0, _createLanguageAsyncLoader["default"])("dts", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dts"));
    });
  }),
  dust: (0, _createLanguageAsyncLoader["default"])("dust", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/dust"));
    });
  }),
  ebnf: (0, _createLanguageAsyncLoader["default"])("ebnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ebnf"));
    });
  }),
  elixir: (0, _createLanguageAsyncLoader["default"])("elixir", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/elixir"));
    });
  }),
  elm: (0, _createLanguageAsyncLoader["default"])("elm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/elm"));
    });
  }),
  erb: (0, _createLanguageAsyncLoader["default"])("erb", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/erb"));
    });
  }),
  erlangRepl: (0, _createLanguageAsyncLoader["default"])("erlangRepl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/erlang-repl"));
    });
  }),
  erlang: (0, _createLanguageAsyncLoader["default"])("erlang", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/erlang"));
    });
  }),
  excel: (0, _createLanguageAsyncLoader["default"])("excel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/excel"));
    });
  }),
  fix: (0, _createLanguageAsyncLoader["default"])("fix", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/fix"));
    });
  }),
  flix: (0, _createLanguageAsyncLoader["default"])("flix", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/flix"));
    });
  }),
  fortran: (0, _createLanguageAsyncLoader["default"])("fortran", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/fortran"));
    });
  }),
  fsharp: (0, _createLanguageAsyncLoader["default"])("fsharp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/fsharp"));
    });
  }),
  gams: (0, _createLanguageAsyncLoader["default"])("gams", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gams"));
    });
  }),
  gauss: (0, _createLanguageAsyncLoader["default"])("gauss", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gauss"));
    });
  }),
  gcode: (0, _createLanguageAsyncLoader["default"])("gcode", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gcode"));
    });
  }),
  gherkin: (0, _createLanguageAsyncLoader["default"])("gherkin", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gherkin"));
    });
  }),
  glsl: (0, _createLanguageAsyncLoader["default"])("glsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/glsl"));
    });
  }),
  gml: (0, _createLanguageAsyncLoader["default"])("gml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gml"));
    });
  }),
  go: (0, _createLanguageAsyncLoader["default"])("go", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/go"));
    });
  }),
  golo: (0, _createLanguageAsyncLoader["default"])("golo", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/golo"));
    });
  }),
  gradle: (0, _createLanguageAsyncLoader["default"])("gradle", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/gradle"));
    });
  }),
  groovy: (0, _createLanguageAsyncLoader["default"])("groovy", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/groovy"));
    });
  }),
  haml: (0, _createLanguageAsyncLoader["default"])("haml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/haml"));
    });
  }),
  handlebars: (0, _createLanguageAsyncLoader["default"])("handlebars", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/handlebars"));
    });
  }),
  haskell: (0, _createLanguageAsyncLoader["default"])("haskell", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/haskell"));
    });
  }),
  haxe: (0, _createLanguageAsyncLoader["default"])("haxe", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/haxe"));
    });
  }),
  hsp: (0, _createLanguageAsyncLoader["default"])("hsp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/hsp"));
    });
  }),
  htmlbars: (0, _createLanguageAsyncLoader["default"])("htmlbars", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/htmlbars"));
    });
  }),
  http: (0, _createLanguageAsyncLoader["default"])("http", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/http"));
    });
  }),
  hy: (0, _createLanguageAsyncLoader["default"])("hy", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/hy"));
    });
  }),
  inform7: (0, _createLanguageAsyncLoader["default"])("inform7", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/inform7"));
    });
  }),
  ini: (0, _createLanguageAsyncLoader["default"])("ini", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ini"));
    });
  }),
  irpf90: (0, _createLanguageAsyncLoader["default"])("irpf90", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/irpf90"));
    });
  }),
  isbl: (0, _createLanguageAsyncLoader["default"])("isbl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/isbl"));
    });
  }),
  java: (0, _createLanguageAsyncLoader["default"])("java", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/java"));
    });
  }),
  javascript: (0, _createLanguageAsyncLoader["default"])("javascript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/javascript"));
    });
  }),
  jbossCli: (0, _createLanguageAsyncLoader["default"])("jbossCli", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/jboss-cli"));
    });
  }),
  json: (0, _createLanguageAsyncLoader["default"])("json", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/json"));
    });
  }),
  juliaRepl: (0, _createLanguageAsyncLoader["default"])("juliaRepl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/julia-repl"));
    });
  }),
  julia: (0, _createLanguageAsyncLoader["default"])("julia", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/julia"));
    });
  }),
  kotlin: (0, _createLanguageAsyncLoader["default"])("kotlin", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/kotlin"));
    });
  }),
  lasso: (0, _createLanguageAsyncLoader["default"])("lasso", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/lasso"));
    });
  }),
  latex: (0, _createLanguageAsyncLoader["default"])("latex", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/latex"));
    });
  }),
  ldif: (0, _createLanguageAsyncLoader["default"])("ldif", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ldif"));
    });
  }),
  leaf: (0, _createLanguageAsyncLoader["default"])("leaf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/leaf"));
    });
  }),
  less: (0, _createLanguageAsyncLoader["default"])("less", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/less"));
    });
  }),
  lisp: (0, _createLanguageAsyncLoader["default"])("lisp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/lisp"));
    });
  }),
  livecodeserver: (0, _createLanguageAsyncLoader["default"])("livecodeserver", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/livecodeserver"));
    });
  }),
  livescript: (0, _createLanguageAsyncLoader["default"])("livescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/livescript"));
    });
  }),
  llvm: (0, _createLanguageAsyncLoader["default"])("llvm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/llvm"));
    });
  }),
  lsl: (0, _createLanguageAsyncLoader["default"])("lsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/lsl"));
    });
  }),
  lua: (0, _createLanguageAsyncLoader["default"])("lua", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/lua"));
    });
  }),
  makefile: (0, _createLanguageAsyncLoader["default"])("makefile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/makefile"));
    });
  }),
  markdown: (0, _createLanguageAsyncLoader["default"])("markdown", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/markdown"));
    });
  }),
  mathematica: (0, _createLanguageAsyncLoader["default"])("mathematica", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mathematica"));
    });
  }),
  matlab: (0, _createLanguageAsyncLoader["default"])("matlab", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/matlab"));
    });
  }),
  maxima: (0, _createLanguageAsyncLoader["default"])("maxima", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/maxima"));
    });
  }),
  mel: (0, _createLanguageAsyncLoader["default"])("mel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mel"));
    });
  }),
  mercury: (0, _createLanguageAsyncLoader["default"])("mercury", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mercury"));
    });
  }),
  mipsasm: (0, _createLanguageAsyncLoader["default"])("mipsasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mipsasm"));
    });
  }),
  mizar: (0, _createLanguageAsyncLoader["default"])("mizar", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mizar"));
    });
  }),
  mojolicious: (0, _createLanguageAsyncLoader["default"])("mojolicious", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/mojolicious"));
    });
  }),
  monkey: (0, _createLanguageAsyncLoader["default"])("monkey", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/monkey"));
    });
  }),
  moonscript: (0, _createLanguageAsyncLoader["default"])("moonscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/moonscript"));
    });
  }),
  n1ql: (0, _createLanguageAsyncLoader["default"])("n1ql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/n1ql"));
    });
  }),
  nginx: (0, _createLanguageAsyncLoader["default"])("nginx", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/nginx"));
    });
  }),
  nim: (0, _createLanguageAsyncLoader["default"])("nim", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/nim"));
    });
  }),
  nix: (0, _createLanguageAsyncLoader["default"])("nix", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/nix"));
    });
  }),
  nodeRepl: (0, _createLanguageAsyncLoader["default"])("nodeRepl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/node-repl"));
    });
  }),
  nsis: (0, _createLanguageAsyncLoader["default"])("nsis", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/nsis"));
    });
  }),
  objectivec: (0, _createLanguageAsyncLoader["default"])("objectivec", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/objectivec"));
    });
  }),
  ocaml: (0, _createLanguageAsyncLoader["default"])("ocaml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ocaml"));
    });
  }),
  openscad: (0, _createLanguageAsyncLoader["default"])("openscad", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/openscad"));
    });
  }),
  oxygene: (0, _createLanguageAsyncLoader["default"])("oxygene", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/oxygene"));
    });
  }),
  parser3: (0, _createLanguageAsyncLoader["default"])("parser3", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/parser3"));
    });
  }),
  perl: (0, _createLanguageAsyncLoader["default"])("perl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/perl"));
    });
  }),
  pf: (0, _createLanguageAsyncLoader["default"])("pf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/pf"));
    });
  }),
  pgsql: (0, _createLanguageAsyncLoader["default"])("pgsql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/pgsql"));
    });
  }),
  phpTemplate: (0, _createLanguageAsyncLoader["default"])("phpTemplate", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/php-template"));
    });
  }),
  php: (0, _createLanguageAsyncLoader["default"])("php", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/php"));
    });
  }),
  plaintext: (0, _createLanguageAsyncLoader["default"])("plaintext", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/plaintext"));
    });
  }),
  pony: (0, _createLanguageAsyncLoader["default"])("pony", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/pony"));
    });
  }),
  powershell: (0, _createLanguageAsyncLoader["default"])("powershell", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/powershell"));
    });
  }),
  processing: (0, _createLanguageAsyncLoader["default"])("processing", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/processing"));
    });
  }),
  profile: (0, _createLanguageAsyncLoader["default"])("profile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/profile"));
    });
  }),
  prolog: (0, _createLanguageAsyncLoader["default"])("prolog", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/prolog"));
    });
  }),
  properties: (0, _createLanguageAsyncLoader["default"])("properties", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/properties"));
    });
  }),
  protobuf: (0, _createLanguageAsyncLoader["default"])("protobuf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/protobuf"));
    });
  }),
  puppet: (0, _createLanguageAsyncLoader["default"])("puppet", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/puppet"));
    });
  }),
  purebasic: (0, _createLanguageAsyncLoader["default"])("purebasic", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/purebasic"));
    });
  }),
  pythonRepl: (0, _createLanguageAsyncLoader["default"])("pythonRepl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/python-repl"));
    });
  }),
  python: (0, _createLanguageAsyncLoader["default"])("python", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/python"));
    });
  }),
  q: (0, _createLanguageAsyncLoader["default"])("q", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/q"));
    });
  }),
  qml: (0, _createLanguageAsyncLoader["default"])("qml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/qml"));
    });
  }),
  r: (0, _createLanguageAsyncLoader["default"])("r", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/r"));
    });
  }),
  reasonml: (0, _createLanguageAsyncLoader["default"])("reasonml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/reasonml"));
    });
  }),
  rib: (0, _createLanguageAsyncLoader["default"])("rib", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/rib"));
    });
  }),
  roboconf: (0, _createLanguageAsyncLoader["default"])("roboconf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/roboconf"));
    });
  }),
  routeros: (0, _createLanguageAsyncLoader["default"])("routeros", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/routeros"));
    });
  }),
  rsl: (0, _createLanguageAsyncLoader["default"])("rsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/rsl"));
    });
  }),
  ruby: (0, _createLanguageAsyncLoader["default"])("ruby", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ruby"));
    });
  }),
  ruleslanguage: (0, _createLanguageAsyncLoader["default"])("ruleslanguage", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/ruleslanguage"));
    });
  }),
  rust: (0, _createLanguageAsyncLoader["default"])("rust", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/rust"));
    });
  }),
  sas: (0, _createLanguageAsyncLoader["default"])("sas", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/sas"));
    });
  }),
  scala: (0, _createLanguageAsyncLoader["default"])("scala", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/scala"));
    });
  }),
  scheme: (0, _createLanguageAsyncLoader["default"])("scheme", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/scheme"));
    });
  }),
  scilab: (0, _createLanguageAsyncLoader["default"])("scilab", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/scilab"));
    });
  }),
  scss: (0, _createLanguageAsyncLoader["default"])("scss", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/scss"));
    });
  }),
  shell: (0, _createLanguageAsyncLoader["default"])("shell", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/shell"));
    });
  }),
  smali: (0, _createLanguageAsyncLoader["default"])("smali", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/smali"));
    });
  }),
  smalltalk: (0, _createLanguageAsyncLoader["default"])("smalltalk", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/smalltalk"));
    });
  }),
  sml: (0, _createLanguageAsyncLoader["default"])("sml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/sml"));
    });
  }),
  sqf: (0, _createLanguageAsyncLoader["default"])("sqf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/sqf"));
    });
  }),
  sql: (0, _createLanguageAsyncLoader["default"])("sql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/sql"));
    });
  }),
  sqlMore: (0, _createLanguageAsyncLoader["default"])("sqlMore", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/sql_more"));
    });
  }),
  stan: (0, _createLanguageAsyncLoader["default"])("stan", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/stan"));
    });
  }),
  stata: (0, _createLanguageAsyncLoader["default"])("stata", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/stata"));
    });
  }),
  step21: (0, _createLanguageAsyncLoader["default"])("step21", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/step21"));
    });
  }),
  stylus: (0, _createLanguageAsyncLoader["default"])("stylus", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/stylus"));
    });
  }),
  subunit: (0, _createLanguageAsyncLoader["default"])("subunit", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/subunit"));
    });
  }),
  swift: (0, _createLanguageAsyncLoader["default"])("swift", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/swift"));
    });
  }),
  taggerscript: (0, _createLanguageAsyncLoader["default"])("taggerscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/taggerscript"));
    });
  }),
  tap: (0, _createLanguageAsyncLoader["default"])("tap", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/tap"));
    });
  }),
  tcl: (0, _createLanguageAsyncLoader["default"])("tcl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/tcl"));
    });
  }),
  thrift: (0, _createLanguageAsyncLoader["default"])("thrift", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/thrift"));
    });
  }),
  tp: (0, _createLanguageAsyncLoader["default"])("tp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/tp"));
    });
  }),
  twig: (0, _createLanguageAsyncLoader["default"])("twig", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/twig"));
    });
  }),
  typescript: (0, _createLanguageAsyncLoader["default"])("typescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/typescript"));
    });
  }),
  vala: (0, _createLanguageAsyncLoader["default"])("vala", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vala"));
    });
  }),
  vbnet: (0, _createLanguageAsyncLoader["default"])("vbnet", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vbnet"));
    });
  }),
  vbscriptHtml: (0, _createLanguageAsyncLoader["default"])("vbscriptHtml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vbscript-html"));
    });
  }),
  vbscript: (0, _createLanguageAsyncLoader["default"])("vbscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vbscript"));
    });
  }),
  verilog: (0, _createLanguageAsyncLoader["default"])("verilog", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/verilog"));
    });
  }),
  vhdl: (0, _createLanguageAsyncLoader["default"])("vhdl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vhdl"));
    });
  }),
  vim: (0, _createLanguageAsyncLoader["default"])("vim", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/vim"));
    });
  }),
  x86asm: (0, _createLanguageAsyncLoader["default"])("x86asm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/x86asm"));
    });
  }),
  xl: (0, _createLanguageAsyncLoader["default"])("xl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/xl"));
    });
  }),
  xml: (0, _createLanguageAsyncLoader["default"])("xml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/xml"));
    });
  }),
  xquery: (0, _createLanguageAsyncLoader["default"])("xquery", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/xquery"));
    });
  }),
  yaml: (0, _createLanguageAsyncLoader["default"])("yaml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/yaml"));
    });
  }),
  zephir: (0, _createLanguageAsyncLoader["default"])("zephir", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("highlight.js/lib/languages/zephir"));
    });
  })
};
exports["default"] = _default;