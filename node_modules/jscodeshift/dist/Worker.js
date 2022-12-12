
/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';

const EventEmitter = require('events').EventEmitter;

const async = require('neo-async');
const fs = require('graceful-fs');
const writeFileAtomic = require('write-file-atomic');
const { DEFAULT_EXTENSIONS } = require('@babel/core');
const getParser = require('./getParser');

const jscodeshift = require('./core');

let emitter;
let finish;
let notify;
let transform;
let parserFromTransform;

if (module.parent) {
  emitter = new EventEmitter();
  emitter.send = (data) => { run(data); };
  finish = () => { emitter.emit('disconnect'); };
  notify = (data) => { emitter.emit('message', data); };
  module.exports = (args) => {
    setup(args[0], args[1]);
    return emitter;
  };
} else {
  finish = () => setImmediate(() => process.disconnect());
  notify = (data) => { process.send(data); };
  process.on('message', (data) => { run(data); });
  setup(process.argv[2], process.argv[3]);
}

function prepareJscodeshift(options) {
  const parser = parserFromTransform ||
    getParser(options.parser, options.parserConfig);
  return jscodeshift.withParser(parser);
}

function setup(tr, babel) {
  if (babel === 'babel') {
    require('@babel/register')({
      babelrc: false,
      presets: [
        [
          require('@babel/preset-env').default,
          {targets: {node: true}},
        ],
        /\.tsx?$/.test(tr) ?
          require('@babel/preset-typescript').default :
          require('@babel/preset-flow').default,
      ],
      plugins: [
        require('@babel/plugin-proposal-class-properties').default,
      ],
      extensions: [...DEFAULT_EXTENSIONS, '.ts', '.tsx'],
      // By default, babel register only compiles things inside the current working directory.
      // https://github.com/babel/babel/blob/2a4f16236656178e84b05b8915aab9261c55782c/packages/babel-register/src/node.js#L140-L157
      ignore: [
        // Ignore parser related files
        /@babel\/parser/,
        /\/flow-parser\//,
        /\/recast\//,
        /\/ast-types\//,
      ],
    });
  }

  const module = require(tr);
  transform = typeof module.default === 'function' ?
    module.default :
    module;
  if (module.parser) {
    parserFromTransform = typeof module.parser === 'string' ?
      getParser(module.parser) :
      module.parser;
  }
}

function free() {
  notify({action: 'free'});
}

function updateStatus(status, file, msg) {
  msg = msg ? file + ' ' + msg : file;
  notify({action: 'status', status: status, msg: msg});
}

function report(file, msg) {
  notify({action: 'report', file, msg});
}

function empty() {}

function stats(name, quantity) {
  quantity = typeof quantity !== 'number' ? 1 : quantity;
  notify({action: 'update', name: name, quantity: quantity});
}

function trimStackTrace(trace) {
  if (!trace) {
    return '';
  }
  // Remove this file from the stack trace of an error thrown in the transformer
  const lines = trace.split('\n');
  const result = [];
  lines.every(function(line) {
    if (line.indexOf(__filename) === -1) {
      result.push(line);
      return true;
    }
  });
  return result.join('\n');
}

function run(data) {
  const files = data.files;
  const options = data.options || {};
  if (!files.length) {
    finish();
    return;
  }
  async.each(
    files,
    function(file, callback) {
      fs.readFile(file, function(err, source) {
        if (err) {
          updateStatus('error', file, 'File error: ' + err);
          callback();
          return;
        }
        source = source.toString();
        try {
          const jscodeshift = prepareJscodeshift(options);
          const out = transform(
            {
              path: file,
              source: source,
            },
            {
              j: jscodeshift,
              jscodeshift: jscodeshift,
              stats: options.dry ? stats : empty,
              report: msg => report(file, msg),
            },
            options
          );
          if (!out || out === source) {
            updateStatus(out ? 'nochange' : 'skip', file);
            callback();
            return;
          }
          if (options.print) {
            console.log(out); // eslint-disable-line no-console
          }
          if (!options.dry) {
            writeFileAtomic(file, out, function(err) {
              if (err) {
                updateStatus('error', file, 'File writer error: ' + err);
              } else {
                updateStatus('ok', file);
              }
              callback();
            });
          } else {
            updateStatus('ok', file);
            callback();
          }
        } catch(err) {
          updateStatus(
            'error',
            file,
            'Transformation error ('+ err.message.replace(/\n/g, ' ') + ')\n' + trimStackTrace(err.stack)
          );
          callback();
        }
      });
    },
    function(err) {
      if (err) {
        updateStatus('error', '', 'This should never be shown!');
      }
      free();
    }
  );
}
