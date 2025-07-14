#!/usr/bin/env node
// @ts-check

import { spawnSync } from 'child_process';
import { resolve } from 'path';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const dir = join(dirname(fileURLToPath(import.meta.url)));

const scriptFile = resolve(dir, '_eslint-interactive.js');

spawnSync('node', ['--unhandled-rejections=strict', scriptFile, ...process.argv.slice(2)], { stdio: 'inherit' });
