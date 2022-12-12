import QUnit from 'qunit';
import window from 'global/window';
import resolveUrl from '../src/resolve-url';

// A modified subset of tests from https://github.com/tjenkinson/url-toolkit

QUnit.module('URL resolver');

QUnit.test('works with a selection of valid urls', function(assert) {
  let currentLocation = '';
  let currentPath = '';

  if (window.location && window.location.protocol) {
    currentLocation = window.location.protocol + '//' + window.location.host;
    currentPath = window.location.pathname.split('/').slice(0, -1).join('/');
  }

  assert.equal(
    resolveUrl('http://a.com/b/cd/e.m3u8', 'https://example.com/z.ts'),
    'https://example.com/z.ts'
  );
  assert.equal(resolveUrl('http://a.com/b/cd/e.m3u8', 'z.ts'), 'http://a.com/b/cd/z.ts');
  assert.equal(resolveUrl('//a.com/b/cd/e.m3u8', 'z.ts'), '//a.com/b/cd/z.ts');
  assert.equal(
    resolveUrl('/a/b/cd/e.m3u8', 'https://example.com:8080/z.ts'),
    'https://example.com:8080/z.ts'
  );
  assert.equal(resolveUrl('/a/b/cd/e.m3u8', 'z.ts'), currentLocation + '/a/b/cd/z.ts');
  assert.equal(resolveUrl('/a/b/cd/e.m3u8', '../../../z.ts'), currentLocation + '/z.ts');

  assert.equal(
    resolveUrl('data:application/dash+xml;charset=utf-8,http%3A%2F%2Fexample.com', 'hello.m3u8'),
    // we need to add the currentPath because we're actually working relative to window.location
    currentLocation + currentPath + '/hello.m3u8',
    'resolves urls relative to window when given a data base url'
  );

  assert.equal(
    resolveUrl('data:application/dash+xml;charset=utf-8,http%3A%2F%2Fexample.com', 'http://example.com/hello.m3u8'),
    'http://example.com/hello.m3u8',
    'absolute urls should still be absolute even with a data uri'
  );

  assert.equal(
    resolveUrl('http://example.com', 'data:application/dash+xml;charset=utf-8,http%3A%2F%2Fexample.com'),
    'data:application/dash+xml;charset=utf-8,http%3A%2F%2Fexample.com',
    'data uri is treated as an absolute url'
  );
});
