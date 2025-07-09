#!/usr/bin/env node

require('./sass.dart.js');
var library = globalThis._cliPkgExports.pop();
if (globalThis._cliPkgExports.length === 0) delete globalThis._cliPkgExports;

library.load({
  readline: require("readline"),
  chokidar: require("chokidar"),
  util: require("util"),
  stream: require("stream"),
  nodeModule: require("module"),
  fs: require("fs"),
  immutable: require("immutable"),
});

library.cli_pkg_main_0_(process.argv.slice(2));
