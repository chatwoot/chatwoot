'use strict';

// tests are adapted from https://github.com/TooTallNate/node-plist

var path = require('path');
var nodeunit = require('nodeunit');
var bplist = require('../');

module.exports = {
  'iTunes Small': function (test) {
    var file = path.join(__dirname, "iTunes-small.bplist");
    var startTime1 = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime1) + 'ms');
      var dict = dicts[0];
      test.equal(dict['Application Version'], "9.0.3");
      test.equal(dict['Library Persistent ID'], "6F81D37F95101437");
      test.done();
    });
  },

  'sample1': function (test) {
    var file = path.join(__dirname, "sample1.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');
      var dict = dicts[0];
      test.equal(dict['CFBundleIdentifier'], 'com.apple.dictionary.MySample');
      test.done();
    });
  },

  'sample2': function (test) {
    var file = path.join(__dirname, "sample2.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');
      var dict = dicts[0];
      test.equal(dict['PopupMenu'][2]['Key'], "\n        #import <Cocoa/Cocoa.h>\n\n#import <MacRuby/MacRuby.h>\n\nint main(int argc, char *argv[])\n{\n  return macruby_main(\"rb_main.rb\", argc, argv);\n}\n");
      test.done();
    });
  },

  'airplay': function (test) {
    var file = path.join(__dirname, "airplay.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');

      var dict = dicts[0];
      test.equal(dict['duration'], 5555.0495000000001);
      test.equal(dict['position'], 4.6269989039999997);
      test.done();
    });
  },

  'utf16': function (test) {
    var file = path.join(__dirname, "utf16.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');

      var dict = dicts[0];
      test.equal(dict['CFBundleName'], 'sellStuff');
      test.equal(dict['CFBundleShortVersionString'], '2.6.1');
      test.equal(dict['NSHumanReadableCopyright'], '©2008-2012, sellStuff, Inc.');
      test.done();
    });
  },

  'utf16chinese': function (test) {
    var file = path.join(__dirname, "utf16_chinese.plist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');

      var dict = dicts[0];
      test.equal(dict['CFBundleName'], '天翼阅读');
      test.equal(dict['CFBundleDisplayName'], '天翼阅读');
      test.done();
    });
  },



  'uid': function (test) {
    var file = path.join(__dirname, "uid.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');

      var dict = dicts[0];
      test.deepEqual(dict['$objects'][1]['NS.keys'], [{UID:2}, {UID:3}, {UID:4}]);
      test.deepEqual(dict['$objects'][1]['NS.objects'], [{UID: 5}, {UID:6}, {UID:7}]);
      test.deepEqual(dict['$top']['root'], {UID:1});
      test.done();
    });
  },
  
  'int64': function (test) {
    var file = path.join(__dirname, "int64.bplist");
    var startTime = new Date();

    bplist.parseFile(file, function (err, dicts) {
      if (err) {
        throw err;
      }

      var endTime = new Date();
      console.log('Parsed "' + file + '" in ' + (endTime - startTime) + 'ms');
      var dict = dicts[0];
      test.equal(dict['zero'], '0');
      test.equal(dict['int64item'], '12345678901234567890');
      test.done();
    });
  }
};
