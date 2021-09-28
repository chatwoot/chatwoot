/* eslint-disable func-names */
import downloadFile from '../fileDownload';

describe('#downloadFile', () => {
  it('should download a file', () => {
    const file = {
      name: 'test.txt',
      content: 'test',
    };
    downloadFile(file);
  });
});
