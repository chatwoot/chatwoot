import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { downloadCsvFile, generateFileName } from '../downloadHelper';

describe('#generateFileName', () => {
  it('should generate the correct file name', () => {
    expect(generateFileName({ type: 'csat', to: 1652812199 })).toEqual(
      'csat-report-17-05-2022.csv'
    );

    expect(
      generateFileName({ type: 'csat', to: 1652812199, businessHours: true })
    ).toEqual('csat-report-17-05-2022-business-hours.csv');
  });
});

describe('#downloadCsvFile', () => {
  const originalCreateElement = document.createElement;
  const originalCreateObjectURL = URL.createObjectURL;
  const originalBlob = globalThis.Blob;

  beforeEach(() => {
    URL.createObjectURL = vi.fn(() => 'blob:csv');
    globalThis.Blob = vi.fn((parts, options) => ({ parts, options }));
    document.createElement = vi.fn(() => ({
      setAttribute: vi.fn(),
      click: vi.fn(),
    }));
  });

  afterEach(() => {
    document.createElement = originalCreateElement;
    URL.createObjectURL = originalCreateObjectURL;
    globalThis.Blob = originalBlob;
  });

  it.each([
    ['name,é', '\uFEFFname,é'],
    ['\uFEFFname,é', '\uFEFFname,é'],
  ])(
    'preserves the UTF-8 BOM in downloaded CSV content',
    (content, expected) => {
      downloadCsvFile('report.csv', content);

      const [blob] = URL.createObjectURL.mock.calls[0];
      expect(blob.parts[0]).toBe(expected);
    }
  );
});
