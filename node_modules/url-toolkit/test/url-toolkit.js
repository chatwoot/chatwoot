const URLToolkit = require('../src/url-toolkit');

describe('url toolkit', () => {
  describe('works with a selection of valid urls', () => {
    // From spec: https://tools.ietf.org/html/rfc1808#section-5.1
    test('http://a/b/c/d;p?q#f', 'g:h', 'g:h');
    test('http://a/b/c/d;p?q#f', 'g', 'http://a/b/c/g');
    test('http://a/b/c/d;p?q#f', './g', 'http://a/b/c/g');
    test('http://a/b/c/d;p?q#f', 'g/', 'http://a/b/c/g/');
    test('http://a/b/c/d;p?q#f', '/g', 'http://a/g');
    test('http://a/b/c/d;p?q#f', '//g', 'http://g');
    test('http://a/b/c/d;p?q#f', '?y', 'http://a/b/c/d;p?y');
    test('http://a/b/c/d;p?q#f', 'g?y', 'http://a/b/c/g?y');
    test('http://a/b/c/d;p?q#f', 'g?y/./x', 'http://a/b/c/g?y/./x');
    test('http://a/b/c/d;p?q#f', '#s', 'http://a/b/c/d;p?q#s');
    test('http://a/b/c/d;p?q#f', 'g#s', 'http://a/b/c/g#s');
    test('http://a/b/c/d;p?q#f', 'g#s/./x', 'http://a/b/c/g#s/./x');
    test('http://a/b/c/d;p?q#f', 'g?y#s', 'http://a/b/c/g?y#s');
    test('http://a/b/c/d;p?q#f', ';x', 'http://a/b/c/d;x');
    test('http://a/b/c/d;p?q#f', 'g;x', 'http://a/b/c/g;x');
    test('http://a/b/c/d;p?q#f', 'g;x?y#s', 'http://a/b/c/g;x?y#s');
    test('http://a/b/c/d;p?q#f', '.', 'http://a/b/c/');
    test('http://a/b/c/d;p?q#f', './', 'http://a/b/c/');
    test('http://a/b/c/d;p?q#f', '..', 'http://a/b/');
    test('http://a/b/c/d;p?q#f', '../', 'http://a/b/');
    test('http://a/b/c/d;p?q#f', '../g', 'http://a/b/g');
    test('http://a/b/c/d;p?q#f', '../..', 'http://a/');
    test('http://a/b/c/d;p?q#f', '../../', 'http://a/');
    test('http://a/b/c/d;p?q#f', '../../g', 'http://a/g');

    test('http://a/b/c/d;p?q#f', '', 'http://a/b/c/d;p?q#f');
    test('http://a/b/c/d;p?q#f', '../../../g', 'http://a/../g');
    test('http://a/b/c/d;p?q#f', '../../../../g', 'http://a/../../g');
    test('http://a/b/c/d;p?q#f', '/./g', 'http://a/./g');
    test('http://a/b/c/d;p?q#f', '/../g', 'http://a/../g');
    test('http://a/b/c/d;p?q#f', 'g.', 'http://a/b/c/g.');
    test('http://a/b/c/d;p?q#f', '.g', 'http://a/b/c/.g');
    test('http://a/b/c/d;p?q#f', 'g..', 'http://a/b/c/g..');
    test('http://a/b/c/d;p?q#f', '..g', 'http://a/b/c/..g');
    test('http://a/b/c/d;p?q#f', './../g', 'http://a/b/g');
    test('http://a/b/c/d;p?q#f', './g/.', 'http://a/b/c/g/');
    test('http://a/b/c/d;p?q#f', 'g/./h', 'http://a/b/c/g/h');
    test('http://a/b/c/d;p?q#f', 'g/../h', 'http://a/b/c/h');

    test('http://a/b/c/d;p?q#f', 'http:g', 'http:g');
    test('http://a/b/c/d;p?q#f', 'http:', 'http:');

    // Custom
    test(
      'http://a.com/b/cd/./e.m3u8?test=1#something',
      '',
      'http://a.com/b/cd/./e.m3u8?test=1#something'
    );
    test(
      'http://a.com/b/cd/./e.m3u8?test=1#something',
      '',
      'http://a.com/b/cd/e.m3u8?test=1#something',
      { alwaysNormalize: true }
    );

    test(
      'http://a.com/b/cd/e.m3u8',
      'https://example.com/z.ts',
      'https://example.com/z.ts'
    );
    test('http://a.com/b/cd/e.m3u8', 'g:h', 'g:h');
    test(
      'http://a.com/b/cd/e.m3u8',
      'https://example.com:8080/z.ts',
      'https://example.com:8080/z.ts'
    );

    test('http://a.com/b/cd/e.m3u8', 'z.ts', 'http://a.com/b/cd/z.ts');
    test(
      'http://a.com:8080/b/cd/e.m3u8',
      'z.ts',
      'http://a.com:8080/b/cd/z.ts'
    );
    test('http://a.com/b/cd/', 'z.ts', 'http://a.com/b/cd/z.ts');
    test('http://a.com/b/cd', 'z.ts', 'http://a.com/b/z.ts');
    test('http://a.com/', 'z.ts', 'http://a.com/z.ts');
    test('http://a.com/?test=1', 'z.ts', 'http://a.com/z.ts');
    test('http://a.com', 'z.ts', 'http://a.com/z.ts');
    test('http://a.com?test=1', 'z.ts', 'http://a.com/z.ts');
    test('http://a.com/b/cd?test=1', 'z.ts', 'http://a.com/b/z.ts');
    test('http://a.com/b/cd#something', 'z.ts', 'http://a.com/b/z.ts');
    test('http://a.com/b/cd?test=1#something', 'z.ts', 'http://a.com/b/z.ts');
    test(
      'http://a.com/b/cd?test=1#something',
      'z.ts?abc=1',
      'http://a.com/b/z.ts?abc=1'
    );
    test(
      'http://a.com/b/cd?test=1#something',
      'z.ts#test',
      'http://a.com/b/z.ts#test'
    );
    test(
      'http://a.com/b/cd?test=1#something',
      'z.ts?abc=1#test',
      'http://a.com/b/z.ts?abc=1#test'
    );

    test('http://a.com/b/cd?test=1#something', ';x', 'http://a.com/b/cd;x');
    test('http://a.com/b/cd?test=1#something', './;x', 'http://a.com/b/;x');
    test('http://a.com/b/cd?test=1#something', 'g;x', 'http://a.com/b/g;x');
    test('http://a_b.com/b/cd?test=1#something', 'g;x', 'http://a_b.com/b/g;x');
    test('http://a-b.com/b/cd?test=1#something', 'g;x', 'http://a-b.com/b/g;x');
    test('http://a.b.com/b/cd?test=1#something', 'g;x', 'http://a.b.com/b/g;x');
    test('http://a~b.com/b/cd?test=1#something', 'g;x', 'http://a~b.com/b/g;x');

    test('a.com', 'z.ts', 'a.com/z.ts');
    test('a.com/', 'z.ts', 'a.com/z.ts');
    test('a.com/b/cd', 'z.ts', 'a.com/b/z.ts');
    test('a.com/b/cd', '../z.ts', 'a.com/z.ts');
    test('a.com/b/cd', '/z.ts', 'a.com/z.ts');
    test('a.com/b/cd', '/b/z.ts', 'a.com/b/z.ts');

    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      'subdir/z.ts?abc=1#test',
      'http://a.com/b/cd/subdir/z.ts?abc=1#test'
    );
    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      '/subdir/z.ts?abc=1#test',
      'http://a.com/subdir/z.ts?abc=1#test'
    );
    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      '//example.com/z.ts?abc=1#test',
      'http://example.com/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '//example.com/z.ts?abc=1#test',
      'https://example.com/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      './z.ts?abc=1#test',
      'https://a.com/b/cd/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '../z.ts?abc=1#test',
      'https://a.com/b/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      './../z.ts?abc=1#test',
      'https://a.com/b/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '././z.ts?abc=1#test',
      'https://a.com/b/cd/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e/f.m3u8?test=1#something',
      '../../z.ts?abc=1#test',
      'https://a.com/b/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '../../z.ts?abc=1#test',
      'https://a.com/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '../../z.ts?abc=1&something=blah/./../test#test',
      'https://a.com/z.ts?abc=1&something=blah/./../test#test'
    );
    test(
      'https://a.com/b/cd/e/f.m3u8?test=1#something',
      './../../z.ts?abc=1#test',
      'https://a.com/b/z.ts?abc=1#test'
    );

    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      'subdir/pointless/../z.ts?abc=1#test',
      'https://a.com/b/cd/subdir/z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '/subdir/pointless/../z.ts?abc=1#test',
      'https://a.com/subdir/z.ts?abc=1#test',
      { alwaysNormalize: true }
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '/subdir/pointless/../z.ts?abc=1#test',
      'https://a.com/subdir/pointless/../z.ts?abc=1#test'
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '//example.com/subdir/pointless/../z.ts?abc=1#test',
      'https://example.com/subdir/z.ts?abc=1#test',
      { alwaysNormalize: true }
    );
    test(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '//example.com/subdir/pointless/../z.ts?abc=1#test',
      'https://example.com/subdir/pointless/../z.ts?abc=1#test'
    );

    test(
      'https://a-b.something.com/b/cd/e.m3u8?test=1#something',
      '//example.com/subdir/pointless/../z.ts?abc=1#test',
      'https://example.com/subdir/z.ts?abc=1#test',
      { alwaysNormalize: true }
    );
    test(
      'https://a-b.something.com/b/cd/e.m3u8?test=1#something',
      '//example.com/subdir/pointless/../z.ts?abc=1#test',
      'https://example.com/subdir/pointless/../z.ts?abc=1#test'
    );

    test(
      '//a.com/b/cd/e.m3u8',
      'https://example.com/z.ts',
      'https://example.com/z.ts'
    );
    test('//a.com/b/cd/e.m3u8', '//example.com/z.ts', '//example.com/z.ts');
    test(
      '//a.com/b/cd/e.m3u8',
      '/example.com/z.ts',
      '//a.com/example.com/z.ts'
    );
    test('//a.com/b/cd/e.m3u8', 'g:h', 'g:h');
    test(
      '//a.com/b/cd/e.m3u8',
      'https://example.com:8080/z.ts',
      'https://example.com:8080/z.ts'
    );
    test('//a.com/b/cd/e.m3u8', 'z.ts', '//a.com/b/cd/z.ts');
    test('//a.com/b/cd/e.m3u8', '../../z.ts', '//a.com/z.ts');

    test('//a.com/b/cd/e.m3u8', '../../../z.ts', '//a.com/../z.ts');

    test(
      '/a/b/cd/e.m3u8',
      'https://example.com/z.ts',
      'https://example.com/z.ts'
    );
    test('/a/b/cd/e.m3u8', '/example.com/z.ts', '/example.com/z.ts');
    test('/a/b/cd/e.m3u8', '//example.com/z.ts', '//example.com/z.ts');
    test('/a/b/cd/e.m3u8', 'g:h', 'g:h');
    test(
      '/a/b/cd/e.m3u8',
      'https://example.com:8080/z.ts',
      'https://example.com:8080/z.ts'
    );
    test('/a/b/cd/e.m3u8', 'z.ts', '/a/b/cd/z.ts');
    test('/a/b/cd/e.m3u8', '../../../z.ts', '/z.ts');

    test('http://ö.de/a/b', 'z.ts', 'http://ö.de/a/z.ts');
    test('http://ö.de/a', 'z.ts', 'http://ö.de/z.ts');
    test('http://ö.de/', 'z.ts', 'http://ö.de/z.ts');
    test('http://ö.de', 'z.ts', 'http://ö.de/z.ts');
    test('ö.de', 'z.ts', 'ö.de/z.ts');

    test('http://a/b/c/d;p?q', './', 'http://a/b/c/');
    test('http://a/b/c/d;p?q', '.', 'http://a/b/c/');
    test('http://a/b/c/d;p?q', '../', 'http://a/b/');
    test('http://a/b/c/d;p?q', '..', 'http://a/b/');

    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      '',
      'http://a.com/b/cd/e.m3u8?test=1#something'
    );

    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      'a_:b',
      'http://a.com/b/cd/a_:b'
    );
    test('http://a.com/b/cd/e.m3u8?test=1#something', 'a:b', 'a:b');
    test(
      'http://a.com/b/cd/e.m3u8?test=1#something',
      './a:b',
      'http://a.com/b/cd/a:b'
    );

    test(
      'http://a.com/expiretime=111;dirmatch=true/master.m3u8',
      './a:b',
      'http://a.com/expiretime=111;dirmatch=true/a:b'
    );

    test('http://0.0.0.0/a/b.c', 'd', 'http://0.0.0.0/a/d');
    test('http://[0:0:0:0::0]/a/b.c', 'd', 'http://[0:0:0:0::0]/a/d');

    test('http://example.com/', 'a#\nb', 'http://example.com/a#\nb');

    // in the URL living standard (https://url.spec.whatwg.org/)
    // `http` is a 'special scheme', and that results in
    // the `///` becoming `//`, meaning `netLoc` would essentially be
    // `//example.com` instead of `//`
    // This library is specifically RFC 1808, which does not have these
    // special cases.
    test('http:///example.com/a/', '../../b', 'http:///b');
  });
});

function test(base, relative, expected, opts) {
  opts = opts || {};
  it(`"${base}" + "${relative}" ${JSON.stringify(opts)}`, () => {
    expect(URLToolkit.parseURL(base)).toMatchSnapshot();
    expect(URLToolkit.parseURL(relative)).toMatchSnapshot();
    expect(URLToolkit.buildURLFromParts(URLToolkit.parseURL(relative))).toBe(
      relative
    );
    expect(URLToolkit.buildURLFromParts(URLToolkit.parseURL(base))).toBe(base);
    expect(URLToolkit.buildAbsoluteURL(base, relative, opts)).toBe(expected);
  });
}
