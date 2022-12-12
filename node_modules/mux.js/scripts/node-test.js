/* eslint-disable no-console */
const path = require('path');
const spawn = require('child_process').spawn;
const major = parseInt(process.versions.node.split('.')[0], 10);
const qunitBinary = require.resolve('qunit/bin/qunit.js');

if (major < 10) {
  console.error('Cannot run tests on node < 10, please update');
  process.exit(1);
}

let args = [qunitBinary, 'test/dist/bundle.js'];

if (major === 10) {
  args = ['node', '--experimental-worker'].concat(args);
}

const child = spawn(args[0], args.slice(1), {
  cwd: path.join(__dirname, '..'),
  stdio: 'inherit'
});

child.on('close', (code) => {
  process.exit(code);
});
