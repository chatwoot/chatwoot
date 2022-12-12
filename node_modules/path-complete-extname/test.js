const assert = require('assert');
const path = require('path');

const pathCompleteExtname = require('.');
const { win32, posix } = pathCompleteExtname;

const isWindows = process.platform === 'win32';


// ---


describe('pathCompleteExtname', function () {

  it('should pass all existing nodejs unit tests', function () {

    const failures = [];
    const slashRE = /\//g;

    [
      [__filename, '.js'],
      ['', ''],
      ['/path/to/file', ''],
      ['/path/to/file.ext', '.ext'],
      ['/path.to/file.ext', '.ext'],
      ['/path.to/file', ''],
      ['/path.to/.file', ''],
      ['/path.to/.file.ext', '.ext'],
      ['/path/to/f.ext', '.ext'],
      ['/path/to/..ext', '.ext'],
      ['/path/to/..', ''],
      ['file', ''],
      ['file.ext', '.ext'],
      ['.file', ''],
      ['.file.ext', '.ext'],
      ['/file', ''],
      ['/file.ext', '.ext'],
      ['/.file', ''],
      ['/.file.ext', '.ext'],
      ['.path/file.ext', '.ext'],
      // ['file.ext.ext', '.ext'],
      ['file.', '.'],
      ['.', ''],
      ['./', ''],
      ['.file.ext', '.ext'],
      ['.file', ''],
      ['.file.', '.'],
      // ['.file..', '.'],
      ['..', ''],
      ['../', ''],
      // ['..file.ext', '.ext'],
      ['..file', '.file'],
      // ['..file.', '.'],
      // ['..file..', '.'],
      ['...', '.'],
      ['...ext', '.ext'],
      // ['....', '.'],
      ['file.ext/', '.ext'],
      ['file.ext//', '.ext'],
      ['file/', ''],
      ['file//', ''],
      ['file./', '.'],
      ['file.//', '.'],
    ].forEach((test) => {
      const expected = test[1];
      [posix, win32].forEach((extname) => {
        let input = test[0];
        let os;
        if (extname === win32) {
          input = input.replace(slashRE, '\\');
          os = 'win32';
        } else {
          os = 'posix';
        }
        const actual = extname(input);
        const message = `path.${os}.extname(${JSON.stringify(input)})\n  expect=${
          JSON.stringify(expected)}\n  actual=${JSON.stringify(actual)}`;
        if (actual !== expected)
          failures.push(`\n${message}`);
      });
      {
        const input = `C:${test[0].replace(slashRE, '\\')}`;
        const actual = win32(input);
        const message = `win32(${JSON.stringify(input)})\n  expect=${
          JSON.stringify(expected)}\n  actual=${JSON.stringify(actual)}`;
        if (actual !== expected)
          failures.push(`\n${message}`);
      }
    });
    assert.strictEqual(failures.length, 0, failures.join(''));

    // On Windows, backslash is a path separator.
    assert.strictEqual(win32('.\\'), '');
    assert.strictEqual(win32('..\\'), '');
    assert.strictEqual(win32('file.ext\\'), '.ext');
    assert.strictEqual(win32('file.ext\\\\'), '.ext');
    assert.strictEqual(win32('file\\'), '');
    assert.strictEqual(win32('file\\\\'), '');
    assert.strictEqual(win32('file.\\'), '.');
    assert.strictEqual(win32('file.\\\\'), '.');

    // On *nix, backslash is a valid name component like any other character.
    assert.strictEqual(posix('.\\'), '');
    assert.strictEqual(posix('..\\'), '.\\');
    assert.strictEqual(posix('file.ext\\'), '.ext\\');
    assert.strictEqual(posix('file.ext\\\\'), '.ext\\\\');
    assert.strictEqual(posix('file\\'), '');
    assert.strictEqual(posix('file\\\\'), '');
    assert.strictEqual(posix('file.\\'), '.\\');
    assert.strictEqual(posix('file.\\\\'), '.\\\\');
  });


  // ---


  it('should retrieve file extensions with two dots', function () {
    assert.equal(pathCompleteExtname('jquery.min.js'), '.min.js');
    assert.equal(pathCompleteExtname('package.tar.gz'), '.tar.gz');
  });


  // ---


  it('should ignore dots on path', function () {
    assert.equal(pathCompleteExtname('/path.to/jquery.min.js'), '.min.js');
  });


  // ---


  it('should not consider initial dot as part of extension', function () {
    assert.equal(pathCompleteExtname('some.path/.yo-rc.json'), '.json');
    assert.equal(pathCompleteExtname('/.yo-rc.json'), '.json');
    assert.equal(pathCompleteExtname('.yo-rc.json'), '.json');
  });


  // ---


  it('should accept a three-dots file extension', function () {
    assert.equal(pathCompleteExtname('some.path/myamazingfile.some.thing.zip'), '.some.thing.zip');
  });


  // ---


  it('should also ignore initial dot if three-dots are present', function () {
    assert.equal(pathCompleteExtname('some.path/.some.thing.zip'), '.thing.zip');
  });


  // ---


  it('should also get version numbers as extensions', function () {
    assert.equal(pathCompleteExtname('some.path/something.0.6.7.js'), '.0.6.7.js');
    assert.equal(pathCompleteExtname('some.path/something.1.2.3.min.js'), '.1.2.3.min.js');
  });

});

