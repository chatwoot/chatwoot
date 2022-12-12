"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uninstall = exports.add = exports.set = exports.install = void 0;
const cp = require("child_process");
const fs = require("fs");
const p = require("path");
const l = (msg) => console.log(`husky - ${msg}`);
const git = (args) => cp.spawnSync('git', args, { stdio: 'inherit' });
function install(dir = '.husky') {
    if (git(['rev-parse']).status !== 0) {
        return;
    }
    const url = 'https://git.io/Jc3F9';
    if (!p.resolve(process.cwd(), dir).startsWith(process.cwd())) {
        throw new Error(`.. not allowed (see ${url})`);
    }
    if (!fs.existsSync('.git')) {
        throw new Error(`.git can't be found (see ${url})`);
    }
    try {
        fs.mkdirSync(p.join(dir, '_'), { recursive: true });
        fs.writeFileSync(p.join(dir, '_/.gitignore'), '*');
        fs.copyFileSync(p.join(__dirname, '../husky.sh'), p.join(dir, '_/husky.sh'));
        const { error } = git(['config', 'core.hooksPath', dir]);
        if (error) {
            throw error;
        }
    }
    catch (e) {
        l('Git hooks failed to install');
        throw e;
    }
    l('Git hooks installed');
}
exports.install = install;
function set(file, cmd) {
    const dir = p.dirname(file);
    if (!fs.existsSync(dir)) {
        throw new Error(`can't create hook, ${dir} directory doesn't exist (try running husky install)`);
    }
    fs.writeFileSync(file, `#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

${cmd}
`, { mode: 0o0755 });
    l(`created ${file}`);
}
exports.set = set;
function add(file, cmd) {
    if (fs.existsSync(file)) {
        fs.appendFileSync(file, `${cmd}\n`);
        l(`updated ${file}`);
    }
    else {
        set(file, cmd);
    }
}
exports.add = add;
function uninstall() {
    git(['config', '--unset', 'core.hooksPath']);
}
exports.uninstall = uninstall;
