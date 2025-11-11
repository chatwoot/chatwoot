import {
  DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE,
  resolveMaximumFileUploadSize,
} from '../FileUploadLimitHelper';

describe('FileUploadLimitHelper', () => {
  it('returns default when value is undefined', () => {
    expect(resolveMaximumFileUploadSize(undefined)).toBe(
      DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
    );
  });

  it('returns default when value is not a positive number', () => {
    expect(resolveMaximumFileUploadSize('not-a-number')).toBe(
      DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
    );
    expect(resolveMaximumFileUploadSize(-5)).toBe(
      DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
    );
  });

  it('parses numeric strings and numbers', () => {
    expect(resolveMaximumFileUploadSize('50')).toBe(50);
    expect(resolveMaximumFileUploadSize(75)).toBe(75);
  });
});
