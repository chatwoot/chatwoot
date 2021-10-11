import { downloadCsvFile } from '../downloadCsvFile';

const fileName = 'test.csv';
const fileData = `Agent name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
Pranav,36,114,28411`;

describe('#downloadCsvFile', () => {
  it('should download the csv file', () => {
    const link = {
      click: jest.fn(),
    };
    jest.spyOn(document, 'createElement').mockImplementation(() => link);

    downloadCsvFile(fileName, fileData);
    expect(link.download).toEqual(fileName);
    expect(link.href).toEqual(
      `data:text/csv;charset=utf-8,${encodeURI(fileData)}`
    );
    expect(link.click).toHaveBeenCalledTimes(1);
  });
});
