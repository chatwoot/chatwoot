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
  const originalCreateObjectURL = URL.createObjectURL;
  let blobs;

  beforeEach(() => {
    blobs = [];
    URL.createObjectURL = vi.fn(blob => {
      blobs.push(blob);
      return 'blob:mock';
    });
  });

  afterEach(() => {
    URL.createObjectURL = originalCreateObjectURL;
  });

  // Read the raw bytes: decoding the blob as text would strip the BOM,
  // which is exactly what the helper is guarding against.
  const readBytes = blob =>
    new Promise(resolve => {
      const reader = new FileReader();
      reader.onload = () => resolve(Array.from(new Uint8Array(reader.result)));
      reader.readAsArrayBuffer(blob);
    });

  const UTF8_BOM_BYTES = [0xef, 0xbb, 0xbf];
  const encode = text => Array.from(new TextEncoder().encode(text));

  it('prepends a UTF-8 BOM so spreadsheet applications detect the encoding', async () => {
    const link = downloadCsvFile('report.csv', 'name\nИван');

    expect(link.getAttribute('download')).toEqual('report.csv');
    expect(blobs).toHaveLength(1);
    expect(await readBytes(blobs[0])).toEqual([
      ...UTF8_BOM_BYTES,
      ...encode('name\nИван'),
    ]);
  });

  it('does not duplicate an existing BOM', async () => {
    downloadCsvFile('report.csv', '\uFEFFname\nИван');

    expect(await readBytes(blobs[0])).toEqual([
      ...UTF8_BOM_BYTES,
      ...encode('name\nИван'),
    ]);
  });
});
