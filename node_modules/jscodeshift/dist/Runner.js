
/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';

const child_process = require('child_process');
const colors = require('colors/safe');
const fs = require('graceful-fs');
const path = require('path');
const http = require('http');
const https = require('https');
const temp = require('temp');
const ignores = require('./ignoreFiles');

const availableCpus = Math.max(require('os').cpus().length - 1, 1);
const CHUNK_SIZE = 50;

function lineBreak(str) {
  return /\n$/.test(str) ? str : str + '\n';
}

const bufferedWrite = (function() {
  const buffer = [];
  let buffering = false;

  process.stdout.on('drain', () => {
    if (!buffering) return;
    while (buffer.length > 0 && process.stdout.write(buffer.shift()) !== false);
    if (buffer.length === 0) {
      buffering = false;
    }
  });
  return function write(msg) {
    if (buffering) {
      buffer.push(msg);
    }
    if (process.stdout.write(msg) === false) {
      buffering = true;
    }
  };
}());

const log = {
  ok(msg, verbose) {
    verbose >= 2 && bufferedWrite(colors.white.bgGreen(' OKK ') + msg);
  },
  nochange(msg, verbose) {
    verbose >= 1 && bufferedWrite(colors.white.bgYellow(' NOC ') + msg);
  },
  skip(msg, verbose) {
    verbose >= 1 && bufferedWrite(colors.white.bgYellow(' SKIP ') + msg);
  },
  error(msg, verbose) {
    verbose >= 0 && bufferedWrite(colors.white.bgRed(' ERR ') + msg);
  },
};

function report({file, msg}) {
  bufferedWrite(lineBreak(`${colors.white.bgBlue(' REP ')}${file} ${msg}`));
}

function concatAll(arrays) {
  const result = [];
  for (const array of arrays) {
    for (const element of array) {
      result.push(element);
    }
  }
  return result;
}

function showFileStats(fileStats) {
  process.stdout.write(
    'Results: \n'+
    colors.red(fileStats.error + ' errors\n')+
    colors.yellow(fileStats.nochange + ' unmodified\n')+
    colors.yellow(fileStats.skip + ' skipped\n')+
    colors.green(fileStats.ok + ' ok\n')
  );
}

function showStats(stats) {
  const names = Object.keys(stats).sort();
  if (names.length) {
    process.stdout.write(colors.blue('Stats: \n'));
  }
  names.forEach(name => process.stdout.write(name + ': ' + stats[name] + '\n'));
}

function dirFiles (dir, callback, acc) {
  // acc stores files found so far and counts remaining paths to be processed
  acc = acc || { files: [], remaining: 1 };

  function done() {
    // decrement count and return if there are no more paths left to process
    if (!--acc.remaining) {
      callback(acc.files);
    }
  }

  fs.readdir(dir, (err, files) => {
    // if dir does not exist or is not a directory, bail
    // (this should not happen as long as calls do the necessary checks)
    if (err) throw err;

    acc.remaining += files.length;
    files.forEach(file => {
      let name = path.join(dir, file);
      fs.stat(name, (err, stats) => {
        if (err) {
          // probably a symlink issue
          process.stdout.write(
            'Skipping path "' + name + '" which does not exist.\n'
          );
          done();
        } else if (ignores.shouldIgnore(name)) {
          // ignore the path
          done();
        } else if (stats.isDirectory()) {
          dirFiles(name + '/', callback, acc);
        } else {
          acc.files.push(name);
          done();
        }
      });
    });
    done();
  });
}

function getAllFiles(paths, filter) {
  return Promise.all(
    paths.map(file => new Promise(resolve => {
      fs.lstat(file, (err, stat) => {
        if (err) {
          process.stderr.write('Skipping path ' + file + ' which does not exist. \n');
          resolve([]);
          return;
        }

        if (stat.isDirectory()) {
          dirFiles(
            file,
            list => resolve(list.filter(filter))
          );
        } else if (ignores.shouldIgnore(file)) {
          // ignoring the file
          resolve([]);
        } else {
          resolve([file]);
        }
      })
    }))
  ).then(concatAll);
}

function run(transformFile, paths, options) {
  let usedRemoteScript = false;
  const cpus = options.cpus ? Math.min(availableCpus, options.cpus) : availableCpus;
  const extensions =
    options.extensions && options.extensions.split(',').map(ext => '.' + ext);
  const fileCounters = {error: 0, ok: 0, nochange: 0, skip: 0};
  const statsCounter = {};
  const startTime = process.hrtime();

  ignores.add(options.ignorePattern);
  ignores.addFromFile(options.ignoreConfig);

  if (/^http/.test(transformFile)) {
    usedRemoteScript = true;
    return new Promise((resolve, reject) => {
      // call the correct `http` or `https` implementation
      (transformFile.indexOf('https') !== 0 ?  http : https).get(transformFile, (res) => {
        let contents = '';
        res
          .on('data', (d) => {
            contents += d.toString();
          })
          .on('end', () => {
            const ext = path.extname(transformFile);
            temp.open({ prefix: 'jscodeshift', suffix: ext }, (err, info) => {
              if (err) return reject(err);
              fs.write(info.fd, contents, function (err) {
                if (err) return reject(err);
                fs.close(info.fd, function(err) {
                  if (err) return reject(err);
                  transform(info.path).then(resolve, reject);
                });
              });
            });
        })
      })
      .on('error', (e) => {
        reject(e);
      });
    });
  } else if (!fs.existsSync(transformFile)) {
    process.stderr.write(
      colors.white.bgRed('ERROR') + ' Transform file ' + transformFile + ' does not exist \n'
    );
    return;
  } else {
    return transform(transformFile);
  }

  function transform(transformFile) {
    return getAllFiles(
      paths,
      name => !extensions || extensions.indexOf(path.extname(name)) != -1
    ).then(files => {
        const numFiles = files.length;

        if (numFiles === 0) {
          process.stdout.write('No files selected, nothing to do. \n');
          return [];
        }

        const processes = options.runInBand ? 1 : Math.min(numFiles, cpus);
        const chunkSize = processes > 1 ?
          Math.min(Math.ceil(numFiles / processes), CHUNK_SIZE) :
          numFiles;

        let index = 0;
        // return the next chunk of work for a free worker
        function next() {
          if (!options.silent && !options.runInBand && index < numFiles) {
            process.stdout.write(
              'Sending ' +
              Math.min(chunkSize, numFiles-index) +
              ' files to free worker...\n'
            );
          }
          return files.slice(index, index += chunkSize);
        }

        if (!options.silent) {
          process.stdout.write('Processing ' + files.length + ' files... \n');
          if (!options.runInBand) {
            process.stdout.write(
              'Spawning ' + processes +' workers...\n'
            );
          }
          if (options.dry) {
            process.stdout.write(
              colors.green('Running in dry mode, no files will be written! \n')
            );
          }
        }

        const args = [transformFile, options.babel ? 'babel' : 'no-babel'];

        const workers = [];
        for (let i = 0; i < processes; i++) {
          workers.push(options.runInBand ?
            require('./Worker')(args) :
            child_process.fork(require.resolve('./Worker'), args)
          );
        }

        return workers.map(child => {
          child.send({files: next(), options});
          child.on('message', message => {
            switch (message.action) {
              case 'status':
                fileCounters[message.status] += 1;
                log[message.status](lineBreak(message.msg), options.verbose);
                break;
              case 'update':
                if (!statsCounter[message.name]) {
                  statsCounter[message.name] = 0;
                }
                statsCounter[message.name] += message.quantity;
                break;
              case 'free':
                child.send({files: next(), options});
                break;
              case 'report':
                report(message);
                break;
            }
          });
          return new Promise(resolve => child.on('disconnect', resolve));
        });
      })
      .then(pendingWorkers =>
        Promise.all(pendingWorkers).then(() => {
          const endTime = process.hrtime(startTime);
          const timeElapsed = (endTime[0] + endTime[1]/1e9).toFixed(3);
          if (!options.silent) {
            process.stdout.write('All done. \n');
            showFileStats(fileCounters);
            showStats(statsCounter);
            process.stdout.write(
              'Time elapsed: ' + timeElapsed + 'seconds \n'
            );
          }
          if (usedRemoteScript) {
            temp.cleanupSync();
          }
          return Object.assign({
            stats: statsCounter,
            timeElapsed: timeElapsed
          }, fileCounters);
        })
      );
  }
}

exports.run = run;
