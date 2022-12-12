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
  abap: (0, _createLanguageAsyncLoader["default"])("abap", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/abap.js"));
    });
  }),
  abnf: (0, _createLanguageAsyncLoader["default"])("abnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/abnf.js"));
    });
  }),
  actionscript: (0, _createLanguageAsyncLoader["default"])("actionscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/actionscript.js"));
    });
  }),
  ada: (0, _createLanguageAsyncLoader["default"])("ada", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ada.js"));
    });
  }),
  agda: (0, _createLanguageAsyncLoader["default"])("agda", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/agda.js"));
    });
  }),
  al: (0, _createLanguageAsyncLoader["default"])("al", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/al.js"));
    });
  }),
  antlr4: (0, _createLanguageAsyncLoader["default"])("antlr4", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/antlr4.js"));
    });
  }),
  apacheconf: (0, _createLanguageAsyncLoader["default"])("apacheconf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/apacheconf.js"));
    });
  }),
  apex: (0, _createLanguageAsyncLoader["default"])("apex", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/apex.js"));
    });
  }),
  apl: (0, _createLanguageAsyncLoader["default"])("apl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/apl.js"));
    });
  }),
  applescript: (0, _createLanguageAsyncLoader["default"])("applescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/applescript.js"));
    });
  }),
  aql: (0, _createLanguageAsyncLoader["default"])("aql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/aql.js"));
    });
  }),
  arduino: (0, _createLanguageAsyncLoader["default"])("arduino", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/arduino.js"));
    });
  }),
  arff: (0, _createLanguageAsyncLoader["default"])("arff", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/arff.js"));
    });
  }),
  asciidoc: (0, _createLanguageAsyncLoader["default"])("asciidoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/asciidoc.js"));
    });
  }),
  asm6502: (0, _createLanguageAsyncLoader["default"])("asm6502", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/asm6502.js"));
    });
  }),
  asmatmel: (0, _createLanguageAsyncLoader["default"])("asmatmel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/asmatmel.js"));
    });
  }),
  aspnet: (0, _createLanguageAsyncLoader["default"])("aspnet", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/aspnet.js"));
    });
  }),
  autohotkey: (0, _createLanguageAsyncLoader["default"])("autohotkey", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/autohotkey.js"));
    });
  }),
  autoit: (0, _createLanguageAsyncLoader["default"])("autoit", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/autoit.js"));
    });
  }),
  avisynth: (0, _createLanguageAsyncLoader["default"])("avisynth", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/avisynth.js"));
    });
  }),
  avroIdl: (0, _createLanguageAsyncLoader["default"])("avroIdl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/avro-idl.js"));
    });
  }),
  bash: (0, _createLanguageAsyncLoader["default"])("bash", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bash.js"));
    });
  }),
  basic: (0, _createLanguageAsyncLoader["default"])("basic", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/basic.js"));
    });
  }),
  batch: (0, _createLanguageAsyncLoader["default"])("batch", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/batch.js"));
    });
  }),
  bbcode: (0, _createLanguageAsyncLoader["default"])("bbcode", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bbcode.js"));
    });
  }),
  bicep: (0, _createLanguageAsyncLoader["default"])("bicep", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bicep.js"));
    });
  }),
  birb: (0, _createLanguageAsyncLoader["default"])("birb", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/birb.js"));
    });
  }),
  bison: (0, _createLanguageAsyncLoader["default"])("bison", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bison.js"));
    });
  }),
  bnf: (0, _createLanguageAsyncLoader["default"])("bnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bnf.js"));
    });
  }),
  brainfuck: (0, _createLanguageAsyncLoader["default"])("brainfuck", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/brainfuck.js"));
    });
  }),
  brightscript: (0, _createLanguageAsyncLoader["default"])("brightscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/brightscript.js"));
    });
  }),
  bro: (0, _createLanguageAsyncLoader["default"])("bro", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bro.js"));
    });
  }),
  bsl: (0, _createLanguageAsyncLoader["default"])("bsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/bsl.js"));
    });
  }),
  c: (0, _createLanguageAsyncLoader["default"])("c", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/c.js"));
    });
  }),
  cfscript: (0, _createLanguageAsyncLoader["default"])("cfscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cfscript.js"));
    });
  }),
  chaiscript: (0, _createLanguageAsyncLoader["default"])("chaiscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/chaiscript.js"));
    });
  }),
  cil: (0, _createLanguageAsyncLoader["default"])("cil", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cil.js"));
    });
  }),
  clike: (0, _createLanguageAsyncLoader["default"])("clike", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/clike.js"));
    });
  }),
  clojure: (0, _createLanguageAsyncLoader["default"])("clojure", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/clojure.js"));
    });
  }),
  cmake: (0, _createLanguageAsyncLoader["default"])("cmake", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cmake.js"));
    });
  }),
  cobol: (0, _createLanguageAsyncLoader["default"])("cobol", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cobol.js"));
    });
  }),
  coffeescript: (0, _createLanguageAsyncLoader["default"])("coffeescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/coffeescript.js"));
    });
  }),
  concurnas: (0, _createLanguageAsyncLoader["default"])("concurnas", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/concurnas.js"));
    });
  }),
  coq: (0, _createLanguageAsyncLoader["default"])("coq", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/coq.js"));
    });
  }),
  cpp: (0, _createLanguageAsyncLoader["default"])("cpp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cpp.js"));
    });
  }),
  crystal: (0, _createLanguageAsyncLoader["default"])("crystal", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/crystal.js"));
    });
  }),
  csharp: (0, _createLanguageAsyncLoader["default"])("csharp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/csharp.js"));
    });
  }),
  cshtml: (0, _createLanguageAsyncLoader["default"])("cshtml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cshtml.js"));
    });
  }),
  csp: (0, _createLanguageAsyncLoader["default"])("csp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/csp.js"));
    });
  }),
  cssExtras: (0, _createLanguageAsyncLoader["default"])("cssExtras", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/css-extras.js"));
    });
  }),
  css: (0, _createLanguageAsyncLoader["default"])("css", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/css.js"));
    });
  }),
  csv: (0, _createLanguageAsyncLoader["default"])("csv", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/csv.js"));
    });
  }),
  cypher: (0, _createLanguageAsyncLoader["default"])("cypher", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/cypher.js"));
    });
  }),
  d: (0, _createLanguageAsyncLoader["default"])("d", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/d.js"));
    });
  }),
  dart: (0, _createLanguageAsyncLoader["default"])("dart", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dart.js"));
    });
  }),
  dataweave: (0, _createLanguageAsyncLoader["default"])("dataweave", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dataweave.js"));
    });
  }),
  dax: (0, _createLanguageAsyncLoader["default"])("dax", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dax.js"));
    });
  }),
  dhall: (0, _createLanguageAsyncLoader["default"])("dhall", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dhall.js"));
    });
  }),
  diff: (0, _createLanguageAsyncLoader["default"])("diff", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/diff.js"));
    });
  }),
  django: (0, _createLanguageAsyncLoader["default"])("django", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/django.js"));
    });
  }),
  dnsZoneFile: (0, _createLanguageAsyncLoader["default"])("dnsZoneFile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dns-zone-file.js"));
    });
  }),
  docker: (0, _createLanguageAsyncLoader["default"])("docker", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/docker.js"));
    });
  }),
  dot: (0, _createLanguageAsyncLoader["default"])("dot", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/dot.js"));
    });
  }),
  ebnf: (0, _createLanguageAsyncLoader["default"])("ebnf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ebnf.js"));
    });
  }),
  editorconfig: (0, _createLanguageAsyncLoader["default"])("editorconfig", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/editorconfig.js"));
    });
  }),
  eiffel: (0, _createLanguageAsyncLoader["default"])("eiffel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/eiffel.js"));
    });
  }),
  ejs: (0, _createLanguageAsyncLoader["default"])("ejs", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ejs.js"));
    });
  }),
  elixir: (0, _createLanguageAsyncLoader["default"])("elixir", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/elixir.js"));
    });
  }),
  elm: (0, _createLanguageAsyncLoader["default"])("elm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/elm.js"));
    });
  }),
  erb: (0, _createLanguageAsyncLoader["default"])("erb", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/erb.js"));
    });
  }),
  erlang: (0, _createLanguageAsyncLoader["default"])("erlang", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/erlang.js"));
    });
  }),
  etlua: (0, _createLanguageAsyncLoader["default"])("etlua", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/etlua.js"));
    });
  }),
  excelFormula: (0, _createLanguageAsyncLoader["default"])("excelFormula", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/excel-formula.js"));
    });
  }),
  factor: (0, _createLanguageAsyncLoader["default"])("factor", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/factor.js"));
    });
  }),
  falselang: (0, _createLanguageAsyncLoader["default"])("falselang", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/false.js"));
    });
  }),
  firestoreSecurityRules: (0, _createLanguageAsyncLoader["default"])("firestoreSecurityRules", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/firestore-security-rules.js"));
    });
  }),
  flow: (0, _createLanguageAsyncLoader["default"])("flow", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/flow.js"));
    });
  }),
  fortran: (0, _createLanguageAsyncLoader["default"])("fortran", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/fortran.js"));
    });
  }),
  fsharp: (0, _createLanguageAsyncLoader["default"])("fsharp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/fsharp.js"));
    });
  }),
  ftl: (0, _createLanguageAsyncLoader["default"])("ftl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ftl.js"));
    });
  }),
  gap: (0, _createLanguageAsyncLoader["default"])("gap", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gap.js"));
    });
  }),
  gcode: (0, _createLanguageAsyncLoader["default"])("gcode", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gcode.js"));
    });
  }),
  gdscript: (0, _createLanguageAsyncLoader["default"])("gdscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gdscript.js"));
    });
  }),
  gedcom: (0, _createLanguageAsyncLoader["default"])("gedcom", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gedcom.js"));
    });
  }),
  gherkin: (0, _createLanguageAsyncLoader["default"])("gherkin", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gherkin.js"));
    });
  }),
  git: (0, _createLanguageAsyncLoader["default"])("git", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/git.js"));
    });
  }),
  glsl: (0, _createLanguageAsyncLoader["default"])("glsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/glsl.js"));
    });
  }),
  gml: (0, _createLanguageAsyncLoader["default"])("gml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gml.js"));
    });
  }),
  gn: (0, _createLanguageAsyncLoader["default"])("gn", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/gn.js"));
    });
  }),
  goModule: (0, _createLanguageAsyncLoader["default"])("goModule", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/go-module.js"));
    });
  }),
  go: (0, _createLanguageAsyncLoader["default"])("go", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/go.js"));
    });
  }),
  graphql: (0, _createLanguageAsyncLoader["default"])("graphql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/graphql.js"));
    });
  }),
  groovy: (0, _createLanguageAsyncLoader["default"])("groovy", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/groovy.js"));
    });
  }),
  haml: (0, _createLanguageAsyncLoader["default"])("haml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/haml.js"));
    });
  }),
  handlebars: (0, _createLanguageAsyncLoader["default"])("handlebars", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/handlebars.js"));
    });
  }),
  haskell: (0, _createLanguageAsyncLoader["default"])("haskell", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/haskell.js"));
    });
  }),
  haxe: (0, _createLanguageAsyncLoader["default"])("haxe", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/haxe.js"));
    });
  }),
  hcl: (0, _createLanguageAsyncLoader["default"])("hcl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/hcl.js"));
    });
  }),
  hlsl: (0, _createLanguageAsyncLoader["default"])("hlsl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/hlsl.js"));
    });
  }),
  hoon: (0, _createLanguageAsyncLoader["default"])("hoon", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/hoon.js"));
    });
  }),
  hpkp: (0, _createLanguageAsyncLoader["default"])("hpkp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/hpkp.js"));
    });
  }),
  hsts: (0, _createLanguageAsyncLoader["default"])("hsts", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/hsts.js"));
    });
  }),
  http: (0, _createLanguageAsyncLoader["default"])("http", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/http.js"));
    });
  }),
  ichigojam: (0, _createLanguageAsyncLoader["default"])("ichigojam", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ichigojam.js"));
    });
  }),
  icon: (0, _createLanguageAsyncLoader["default"])("icon", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/icon.js"));
    });
  }),
  icuMessageFormat: (0, _createLanguageAsyncLoader["default"])("icuMessageFormat", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/icu-message-format.js"));
    });
  }),
  idris: (0, _createLanguageAsyncLoader["default"])("idris", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/idris.js"));
    });
  }),
  iecst: (0, _createLanguageAsyncLoader["default"])("iecst", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/iecst.js"));
    });
  }),
  ignore: (0, _createLanguageAsyncLoader["default"])("ignore", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ignore.js"));
    });
  }),
  inform7: (0, _createLanguageAsyncLoader["default"])("inform7", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/inform7.js"));
    });
  }),
  ini: (0, _createLanguageAsyncLoader["default"])("ini", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ini.js"));
    });
  }),
  io: (0, _createLanguageAsyncLoader["default"])("io", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/io.js"));
    });
  }),
  j: (0, _createLanguageAsyncLoader["default"])("j", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/j.js"));
    });
  }),
  java: (0, _createLanguageAsyncLoader["default"])("java", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/java.js"));
    });
  }),
  javadoc: (0, _createLanguageAsyncLoader["default"])("javadoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/javadoc.js"));
    });
  }),
  javadoclike: (0, _createLanguageAsyncLoader["default"])("javadoclike", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/javadoclike.js"));
    });
  }),
  javascript: (0, _createLanguageAsyncLoader["default"])("javascript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/javascript.js"));
    });
  }),
  javastacktrace: (0, _createLanguageAsyncLoader["default"])("javastacktrace", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/javastacktrace.js"));
    });
  }),
  jexl: (0, _createLanguageAsyncLoader["default"])("jexl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jexl.js"));
    });
  }),
  jolie: (0, _createLanguageAsyncLoader["default"])("jolie", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jolie.js"));
    });
  }),
  jq: (0, _createLanguageAsyncLoader["default"])("jq", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jq.js"));
    });
  }),
  jsExtras: (0, _createLanguageAsyncLoader["default"])("jsExtras", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/js-extras.js"));
    });
  }),
  jsTemplates: (0, _createLanguageAsyncLoader["default"])("jsTemplates", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/js-templates.js"));
    });
  }),
  jsdoc: (0, _createLanguageAsyncLoader["default"])("jsdoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jsdoc.js"));
    });
  }),
  json: (0, _createLanguageAsyncLoader["default"])("json", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/json.js"));
    });
  }),
  json5: (0, _createLanguageAsyncLoader["default"])("json5", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/json5.js"));
    });
  }),
  jsonp: (0, _createLanguageAsyncLoader["default"])("jsonp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jsonp.js"));
    });
  }),
  jsstacktrace: (0, _createLanguageAsyncLoader["default"])("jsstacktrace", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jsstacktrace.js"));
    });
  }),
  jsx: (0, _createLanguageAsyncLoader["default"])("jsx", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/jsx.js"));
    });
  }),
  julia: (0, _createLanguageAsyncLoader["default"])("julia", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/julia.js"));
    });
  }),
  keepalived: (0, _createLanguageAsyncLoader["default"])("keepalived", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/keepalived.js"));
    });
  }),
  keyman: (0, _createLanguageAsyncLoader["default"])("keyman", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/keyman.js"));
    });
  }),
  kotlin: (0, _createLanguageAsyncLoader["default"])("kotlin", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/kotlin.js"));
    });
  }),
  kumir: (0, _createLanguageAsyncLoader["default"])("kumir", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/kumir.js"));
    });
  }),
  kusto: (0, _createLanguageAsyncLoader["default"])("kusto", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/kusto.js"));
    });
  }),
  latex: (0, _createLanguageAsyncLoader["default"])("latex", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/latex.js"));
    });
  }),
  latte: (0, _createLanguageAsyncLoader["default"])("latte", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/latte.js"));
    });
  }),
  less: (0, _createLanguageAsyncLoader["default"])("less", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/less.js"));
    });
  }),
  lilypond: (0, _createLanguageAsyncLoader["default"])("lilypond", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/lilypond.js"));
    });
  }),
  liquid: (0, _createLanguageAsyncLoader["default"])("liquid", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/liquid.js"));
    });
  }),
  lisp: (0, _createLanguageAsyncLoader["default"])("lisp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/lisp.js"));
    });
  }),
  livescript: (0, _createLanguageAsyncLoader["default"])("livescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/livescript.js"));
    });
  }),
  llvm: (0, _createLanguageAsyncLoader["default"])("llvm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/llvm.js"));
    });
  }),
  log: (0, _createLanguageAsyncLoader["default"])("log", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/log.js"));
    });
  }),
  lolcode: (0, _createLanguageAsyncLoader["default"])("lolcode", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/lolcode.js"));
    });
  }),
  lua: (0, _createLanguageAsyncLoader["default"])("lua", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/lua.js"));
    });
  }),
  magma: (0, _createLanguageAsyncLoader["default"])("magma", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/magma.js"));
    });
  }),
  makefile: (0, _createLanguageAsyncLoader["default"])("makefile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/makefile.js"));
    });
  }),
  markdown: (0, _createLanguageAsyncLoader["default"])("markdown", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/markdown.js"));
    });
  }),
  markupTemplating: (0, _createLanguageAsyncLoader["default"])("markupTemplating", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/markup-templating.js"));
    });
  }),
  markup: (0, _createLanguageAsyncLoader["default"])("markup", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/markup.js"));
    });
  }),
  matlab: (0, _createLanguageAsyncLoader["default"])("matlab", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/matlab.js"));
    });
  }),
  maxscript: (0, _createLanguageAsyncLoader["default"])("maxscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/maxscript.js"));
    });
  }),
  mel: (0, _createLanguageAsyncLoader["default"])("mel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/mel.js"));
    });
  }),
  mermaid: (0, _createLanguageAsyncLoader["default"])("mermaid", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/mermaid.js"));
    });
  }),
  mizar: (0, _createLanguageAsyncLoader["default"])("mizar", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/mizar.js"));
    });
  }),
  mongodb: (0, _createLanguageAsyncLoader["default"])("mongodb", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/mongodb.js"));
    });
  }),
  monkey: (0, _createLanguageAsyncLoader["default"])("monkey", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/monkey.js"));
    });
  }),
  moonscript: (0, _createLanguageAsyncLoader["default"])("moonscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/moonscript.js"));
    });
  }),
  n1ql: (0, _createLanguageAsyncLoader["default"])("n1ql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/n1ql.js"));
    });
  }),
  n4js: (0, _createLanguageAsyncLoader["default"])("n4js", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/n4js.js"));
    });
  }),
  nand2tetrisHdl: (0, _createLanguageAsyncLoader["default"])("nand2tetrisHdl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nand2tetris-hdl.js"));
    });
  }),
  naniscript: (0, _createLanguageAsyncLoader["default"])("naniscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/naniscript.js"));
    });
  }),
  nasm: (0, _createLanguageAsyncLoader["default"])("nasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nasm.js"));
    });
  }),
  neon: (0, _createLanguageAsyncLoader["default"])("neon", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/neon.js"));
    });
  }),
  nevod: (0, _createLanguageAsyncLoader["default"])("nevod", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nevod.js"));
    });
  }),
  nginx: (0, _createLanguageAsyncLoader["default"])("nginx", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nginx.js"));
    });
  }),
  nim: (0, _createLanguageAsyncLoader["default"])("nim", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nim.js"));
    });
  }),
  nix: (0, _createLanguageAsyncLoader["default"])("nix", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nix.js"));
    });
  }),
  nsis: (0, _createLanguageAsyncLoader["default"])("nsis", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/nsis.js"));
    });
  }),
  objectivec: (0, _createLanguageAsyncLoader["default"])("objectivec", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/objectivec.js"));
    });
  }),
  ocaml: (0, _createLanguageAsyncLoader["default"])("ocaml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ocaml.js"));
    });
  }),
  opencl: (0, _createLanguageAsyncLoader["default"])("opencl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/opencl.js"));
    });
  }),
  openqasm: (0, _createLanguageAsyncLoader["default"])("openqasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/openqasm.js"));
    });
  }),
  oz: (0, _createLanguageAsyncLoader["default"])("oz", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/oz.js"));
    });
  }),
  parigp: (0, _createLanguageAsyncLoader["default"])("parigp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/parigp.js"));
    });
  }),
  parser: (0, _createLanguageAsyncLoader["default"])("parser", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/parser.js"));
    });
  }),
  pascal: (0, _createLanguageAsyncLoader["default"])("pascal", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/pascal.js"));
    });
  }),
  pascaligo: (0, _createLanguageAsyncLoader["default"])("pascaligo", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/pascaligo.js"));
    });
  }),
  pcaxis: (0, _createLanguageAsyncLoader["default"])("pcaxis", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/pcaxis.js"));
    });
  }),
  peoplecode: (0, _createLanguageAsyncLoader["default"])("peoplecode", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/peoplecode.js"));
    });
  }),
  perl: (0, _createLanguageAsyncLoader["default"])("perl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/perl.js"));
    });
  }),
  phpExtras: (0, _createLanguageAsyncLoader["default"])("phpExtras", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/php-extras.js"));
    });
  }),
  php: (0, _createLanguageAsyncLoader["default"])("php", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/php.js"));
    });
  }),
  phpdoc: (0, _createLanguageAsyncLoader["default"])("phpdoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/phpdoc.js"));
    });
  }),
  plsql: (0, _createLanguageAsyncLoader["default"])("plsql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/plsql.js"));
    });
  }),
  powerquery: (0, _createLanguageAsyncLoader["default"])("powerquery", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/powerquery.js"));
    });
  }),
  powershell: (0, _createLanguageAsyncLoader["default"])("powershell", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/powershell.js"));
    });
  }),
  processing: (0, _createLanguageAsyncLoader["default"])("processing", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/processing.js"));
    });
  }),
  prolog: (0, _createLanguageAsyncLoader["default"])("prolog", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/prolog.js"));
    });
  }),
  promql: (0, _createLanguageAsyncLoader["default"])("promql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/promql.js"));
    });
  }),
  properties: (0, _createLanguageAsyncLoader["default"])("properties", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/properties.js"));
    });
  }),
  protobuf: (0, _createLanguageAsyncLoader["default"])("protobuf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/protobuf.js"));
    });
  }),
  psl: (0, _createLanguageAsyncLoader["default"])("psl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/psl.js"));
    });
  }),
  pug: (0, _createLanguageAsyncLoader["default"])("pug", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/pug.js"));
    });
  }),
  puppet: (0, _createLanguageAsyncLoader["default"])("puppet", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/puppet.js"));
    });
  }),
  pure: (0, _createLanguageAsyncLoader["default"])("pure", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/pure.js"));
    });
  }),
  purebasic: (0, _createLanguageAsyncLoader["default"])("purebasic", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/purebasic.js"));
    });
  }),
  purescript: (0, _createLanguageAsyncLoader["default"])("purescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/purescript.js"));
    });
  }),
  python: (0, _createLanguageAsyncLoader["default"])("python", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/python.js"));
    });
  }),
  q: (0, _createLanguageAsyncLoader["default"])("q", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/q.js"));
    });
  }),
  qml: (0, _createLanguageAsyncLoader["default"])("qml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/qml.js"));
    });
  }),
  qore: (0, _createLanguageAsyncLoader["default"])("qore", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/qore.js"));
    });
  }),
  qsharp: (0, _createLanguageAsyncLoader["default"])("qsharp", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/qsharp.js"));
    });
  }),
  r: (0, _createLanguageAsyncLoader["default"])("r", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/r.js"));
    });
  }),
  racket: (0, _createLanguageAsyncLoader["default"])("racket", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/racket.js"));
    });
  }),
  reason: (0, _createLanguageAsyncLoader["default"])("reason", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/reason.js"));
    });
  }),
  regex: (0, _createLanguageAsyncLoader["default"])("regex", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/regex.js"));
    });
  }),
  rego: (0, _createLanguageAsyncLoader["default"])("rego", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/rego.js"));
    });
  }),
  renpy: (0, _createLanguageAsyncLoader["default"])("renpy", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/renpy.js"));
    });
  }),
  rest: (0, _createLanguageAsyncLoader["default"])("rest", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/rest.js"));
    });
  }),
  rip: (0, _createLanguageAsyncLoader["default"])("rip", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/rip.js"));
    });
  }),
  roboconf: (0, _createLanguageAsyncLoader["default"])("roboconf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/roboconf.js"));
    });
  }),
  robotframework: (0, _createLanguageAsyncLoader["default"])("robotframework", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/robotframework.js"));
    });
  }),
  ruby: (0, _createLanguageAsyncLoader["default"])("ruby", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/ruby.js"));
    });
  }),
  rust: (0, _createLanguageAsyncLoader["default"])("rust", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/rust.js"));
    });
  }),
  sas: (0, _createLanguageAsyncLoader["default"])("sas", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sas.js"));
    });
  }),
  sass: (0, _createLanguageAsyncLoader["default"])("sass", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sass.js"));
    });
  }),
  scala: (0, _createLanguageAsyncLoader["default"])("scala", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/scala.js"));
    });
  }),
  scheme: (0, _createLanguageAsyncLoader["default"])("scheme", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/scheme.js"));
    });
  }),
  scss: (0, _createLanguageAsyncLoader["default"])("scss", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/scss.js"));
    });
  }),
  shellSession: (0, _createLanguageAsyncLoader["default"])("shellSession", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/shell-session.js"));
    });
  }),
  smali: (0, _createLanguageAsyncLoader["default"])("smali", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/smali.js"));
    });
  }),
  smalltalk: (0, _createLanguageAsyncLoader["default"])("smalltalk", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/smalltalk.js"));
    });
  }),
  smarty: (0, _createLanguageAsyncLoader["default"])("smarty", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/smarty.js"));
    });
  }),
  sml: (0, _createLanguageAsyncLoader["default"])("sml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sml.js"));
    });
  }),
  solidity: (0, _createLanguageAsyncLoader["default"])("solidity", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/solidity.js"));
    });
  }),
  solutionFile: (0, _createLanguageAsyncLoader["default"])("solutionFile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/solution-file.js"));
    });
  }),
  soy: (0, _createLanguageAsyncLoader["default"])("soy", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/soy.js"));
    });
  }),
  sparql: (0, _createLanguageAsyncLoader["default"])("sparql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sparql.js"));
    });
  }),
  splunkSpl: (0, _createLanguageAsyncLoader["default"])("splunkSpl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/splunk-spl.js"));
    });
  }),
  sqf: (0, _createLanguageAsyncLoader["default"])("sqf", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sqf.js"));
    });
  }),
  sql: (0, _createLanguageAsyncLoader["default"])("sql", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/sql.js"));
    });
  }),
  squirrel: (0, _createLanguageAsyncLoader["default"])("squirrel", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/squirrel.js"));
    });
  }),
  stan: (0, _createLanguageAsyncLoader["default"])("stan", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/stan.js"));
    });
  }),
  stylus: (0, _createLanguageAsyncLoader["default"])("stylus", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/stylus.js"));
    });
  }),
  swift: (0, _createLanguageAsyncLoader["default"])("swift", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/swift.js"));
    });
  }),
  systemd: (0, _createLanguageAsyncLoader["default"])("systemd", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/systemd.js"));
    });
  }),
  t4Cs: (0, _createLanguageAsyncLoader["default"])("t4Cs", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/t4-cs.js"));
    });
  }),
  t4Templating: (0, _createLanguageAsyncLoader["default"])("t4Templating", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/t4-templating.js"));
    });
  }),
  t4Vb: (0, _createLanguageAsyncLoader["default"])("t4Vb", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/t4-vb.js"));
    });
  }),
  tap: (0, _createLanguageAsyncLoader["default"])("tap", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/tap.js"));
    });
  }),
  tcl: (0, _createLanguageAsyncLoader["default"])("tcl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/tcl.js"));
    });
  }),
  textile: (0, _createLanguageAsyncLoader["default"])("textile", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/textile.js"));
    });
  }),
  toml: (0, _createLanguageAsyncLoader["default"])("toml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/toml.js"));
    });
  }),
  tremor: (0, _createLanguageAsyncLoader["default"])("tremor", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/tremor.js"));
    });
  }),
  tsx: (0, _createLanguageAsyncLoader["default"])("tsx", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/tsx.js"));
    });
  }),
  tt2: (0, _createLanguageAsyncLoader["default"])("tt2", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/tt2.js"));
    });
  }),
  turtle: (0, _createLanguageAsyncLoader["default"])("turtle", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/turtle.js"));
    });
  }),
  twig: (0, _createLanguageAsyncLoader["default"])("twig", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/twig.js"));
    });
  }),
  typescript: (0, _createLanguageAsyncLoader["default"])("typescript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/typescript.js"));
    });
  }),
  typoscript: (0, _createLanguageAsyncLoader["default"])("typoscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/typoscript.js"));
    });
  }),
  unrealscript: (0, _createLanguageAsyncLoader["default"])("unrealscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/unrealscript.js"));
    });
  }),
  uorazor: (0, _createLanguageAsyncLoader["default"])("uorazor", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/uorazor.js"));
    });
  }),
  uri: (0, _createLanguageAsyncLoader["default"])("uri", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/uri.js"));
    });
  }),
  v: (0, _createLanguageAsyncLoader["default"])("v", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/v.js"));
    });
  }),
  vala: (0, _createLanguageAsyncLoader["default"])("vala", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/vala.js"));
    });
  }),
  vbnet: (0, _createLanguageAsyncLoader["default"])("vbnet", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/vbnet.js"));
    });
  }),
  velocity: (0, _createLanguageAsyncLoader["default"])("velocity", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/velocity.js"));
    });
  }),
  verilog: (0, _createLanguageAsyncLoader["default"])("verilog", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/verilog.js"));
    });
  }),
  vhdl: (0, _createLanguageAsyncLoader["default"])("vhdl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/vhdl.js"));
    });
  }),
  vim: (0, _createLanguageAsyncLoader["default"])("vim", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/vim.js"));
    });
  }),
  visualBasic: (0, _createLanguageAsyncLoader["default"])("visualBasic", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/visual-basic.js"));
    });
  }),
  warpscript: (0, _createLanguageAsyncLoader["default"])("warpscript", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/warpscript.js"));
    });
  }),
  wasm: (0, _createLanguageAsyncLoader["default"])("wasm", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/wasm.js"));
    });
  }),
  webIdl: (0, _createLanguageAsyncLoader["default"])("webIdl", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/web-idl.js"));
    });
  }),
  wiki: (0, _createLanguageAsyncLoader["default"])("wiki", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/wiki.js"));
    });
  }),
  wolfram: (0, _createLanguageAsyncLoader["default"])("wolfram", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/wolfram.js"));
    });
  }),
  wren: (0, _createLanguageAsyncLoader["default"])("wren", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/wren.js"));
    });
  }),
  xeora: (0, _createLanguageAsyncLoader["default"])("xeora", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/xeora.js"));
    });
  }),
  xmlDoc: (0, _createLanguageAsyncLoader["default"])("xmlDoc", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/xml-doc.js"));
    });
  }),
  xojo: (0, _createLanguageAsyncLoader["default"])("xojo", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/xojo.js"));
    });
  }),
  xquery: (0, _createLanguageAsyncLoader["default"])("xquery", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/xquery.js"));
    });
  }),
  yaml: (0, _createLanguageAsyncLoader["default"])("yaml", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/yaml.js"));
    });
  }),
  yang: (0, _createLanguageAsyncLoader["default"])("yang", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/yang.js"));
    });
  }),
  zig: (0, _createLanguageAsyncLoader["default"])("zig", function () {
    return Promise.resolve().then(function () {
      return _interopRequireWildcard(require("refractor/lang/zig.js"));
    });
  })
};
exports["default"] = _default;