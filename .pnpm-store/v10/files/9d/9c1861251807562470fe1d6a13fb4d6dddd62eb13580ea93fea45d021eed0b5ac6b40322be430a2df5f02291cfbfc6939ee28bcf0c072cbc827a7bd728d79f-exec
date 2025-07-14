#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require('fs');
const path = require('path');
const {Transmuxer} = require('../lib/mp4');
const {version} = require('../package.json');
const {concatTypedArrays} = require('@videojs/vhs-utils/cjs/byte-helpers');
const {ONE_SECOND_IN_TS} = require('../lib/utils/clock.js');

const showHelp = function() {
  console.log(`
  transmux media-file > foo.mp4
  transmux media-file -o foo.mp4
  curl -s 'some-media-ulr' | transmux.js -o foo.mp4
  wget -O - -o /dev/null 'some-media-url' | transmux.js -o foo.mp4

  transmux a supported segment (ts or adts) info an fmp4

  -h, --help                 print help
  -v, --version              print the version
  -o, --output    <string>   write to a file instead of stdout
  -d, --debugger             add a break point just before data goes to transmuxer
`);
};

const parseArgs = function(args) {
  const options = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if ((/^--version|-v$/).test(arg)) {
      console.log(`transmux.js v${version}`);
      process.exit(0);
    } else if ((/^--help|-h$/).test(arg)) {
      showHelp();
      process.exit(0);
    } else if ((/^--debugger|-d$/).test(arg)) {
      options.debugger = true;
    } else if ((/^--output|-o$/).test(arg)) {
      i++;
      options.output = args[i];
    } else {
      options.file = arg;
    }
  }

  return options;
};

const cli = function(stdin) {
  const options = parseArgs(process.argv.slice(2));
  let inputStream;
  let outputStream;

  // if stdin was provided
  if (stdin && options.file) {
    console.error(`You cannot pass in a file ${options.file} and pipe from stdin!`);
    process.exit(1);
  }

  if (stdin) {
    inputStream = process.stdin;
  } else if (options.file) {
    inputStream = fs.createReadStream(path.resolve(options.file));
  }

  if (!inputStream) {
    console.error('A file or stdin must be passed in as an argument or via pipeing to this script!');
    process.exit(1);
  }

  if (options.output) {
    outputStream = fs.createWriteStream(path.resolve(options.output), {
      encoding: null
    });
  } else {
    outputStream = process.stdout;
  }

  return new Promise(function(resolve, reject) {
    let allData;

    inputStream.on('data', (chunk) => {
      allData = concatTypedArrays(allData, chunk);
    });
    inputStream.on('error', reject);

    inputStream.on('close', () => {
      if (!allData || !allData.length) {
        return reject('file is empty');
      }
      resolve(allData);
    });
  }).then(function(inputData) {
    const transmuxer = new Transmuxer();

    // Setting the BMDT to ensure that captions and id3 tags are not
    // time-shifted by this value when they are output and instead are
    // zero-based
    transmuxer.setBaseMediaDecodeTime(ONE_SECOND_IN_TS);

    transmuxer.on('data', function(data) {
      if (data.initSegment) {
        outputStream.write(concatTypedArrays(data.initSegment, data.data));
      } else {
        outputStream.write(data.data);
      }
    });

    if (options.debugger) {
      // eslint-disable-next-line
      debugger;
    }
    transmuxer.push(inputData);
    transmuxer.flush();
    process.exit(0);
  }).catch(function(e) {
    console.error(e);
    process.exit(1);
  });
};

// no stdin if isTTY is set
cli(!process.stdin.isTTY ? process.stdin : null);
