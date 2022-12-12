#!/usr/bin/env node

var extract = require('./')

var args = process.argv.slice(2)
var source = args[0]
var dest = args[1] || process.cwd()
if (!source) {
  console.error('Usage: extract-zip foo.zip <targetDirectory>')
  process.exit(1)
}

extract(source, {dir: dest}, function (err, results) {
  if (err) {
    console.error('error!', err)
    process.exit(1)
  } else {
    process.exit(0)
  }
})
