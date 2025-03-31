#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const p = require("path");
const h = require("./");
function help(code) {
    console.log(`Usage:
  husky install [dir] (default: .husky)
  husky uninstall
  husky set|add <file> [cmd]`);
    process.exit(code);
}
const [, , cmd, ...args] = process.argv;
const ln = args.length;
const [x, y] = args;
const hook = (fn) => () => !ln || ln > 2 ? help(2) : fn(x, y);
const cmds = {
    install: () => (ln > 1 ? help(2) : h.install(x)),
    uninstall: h.uninstall,
    set: hook(h.set),
    add: hook(h.add),
    ['-v']: () => console.log(require(p.join(__dirname, '../package.json')).version),
};
try {
    cmds[cmd] ? cmds[cmd]() : help(0);
}
catch (e) {
    console.error(e.message);
    process.exit(1);
}
