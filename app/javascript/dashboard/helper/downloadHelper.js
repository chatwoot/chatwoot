import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

export const downloadCsvFile = (fileName, fileContent) => {
  const link = document.createElement('a');
  link.download = fileName;
  link.href = `data:text/csv;charset=utf-8,` + encodeURI(fileContent);
  link.click();
};

export const generateFileName = ({ type, to }) =>
  `${type}-report-${format(fromUnixTime(to), 'dd-MM-yyyy')}.csv`;
