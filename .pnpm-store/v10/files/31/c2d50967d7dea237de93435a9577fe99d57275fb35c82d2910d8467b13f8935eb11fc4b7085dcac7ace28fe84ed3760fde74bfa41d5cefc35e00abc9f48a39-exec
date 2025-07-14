#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const {parse} = require('../dist/mpd-parser.cjs.js');

const file = path.resolve(process.cwd(), process.argv[2]);
const result = parse(fs.readFileSync(file, 'utf8'), {
  manifestUri: ''
});

console.log(JSON.stringify(result, null, 2));
