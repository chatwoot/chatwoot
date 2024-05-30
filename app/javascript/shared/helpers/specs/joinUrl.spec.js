import { joinUrl } from '../joinUrl';

describe('joinUrl', () => {
  it('should correctly join base URL and multiple paths', () => {
    expect(joinUrl('http://example.com', 'path1', 'path2', 'path3')).toBe(
      'http://example.com/path1/path2/path3'
    );
  });

  it('should handle trailing slashes on the base URL', () => {
    expect(joinUrl('http://example.com/', 'path1', 'path2')).toBe(
      'http://example.com/path1/path2'
    );
  });

  it('should handle leading and trailing slashes on path segments', () => {
    expect(joinUrl('http://example.com', '/path1/', '/path2/')).toBe(
      'http://example.com/path1/path2'
    );
  });

  it('should handle a mix of slashes in base URL and paths', () => {
    expect(joinUrl('http://example.com/', '/path1/', '/path2/')).toBe(
      'http://example.com/path1/path2'
    );
  });

  it('should return the base URL if no paths are provided', () => {
    expect(joinUrl('http://example.com')).toBe('http://example.com');
  });

  it('should handle empty path segments', () => {
    expect(joinUrl('http://example.com', '', 'path1', '', 'path2')).toBe(
      'http://example.com/path1/path2'
    );
  });

  it('should handle paths that are just slashes', () => {
    expect(joinUrl('http://example.com', '/', '//', '/path1/', '/')).toBe(
      'http://example.com/path1'
    );
  });

  it('should handle null and undefined paths', () => {
    expect(
      joinUrl('http://example.com', null, 'path1', undefined, 'path2')
    ).toBe('http://example.com/path1/path2');
  });

  it('should handle paths with multiple consecutive slashes', () => {
    expect(joinUrl('http://example.com', '///path1///', 'path2///')).toBe(
      'http://example.com/path1/path2'
    );
  });

  it('should handle only slashes in base URL and paths', () => {
    expect(joinUrl('http://example.com/', '/', '/')).toBe('http://example.com');
  });
});
