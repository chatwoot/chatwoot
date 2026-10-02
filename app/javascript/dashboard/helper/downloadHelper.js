import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

// Spreadsheet applications such as Excel only detect UTF-8 when the file
// starts with a byte order mark. The API prepends one to CSV responses, but
// the browser strips it while decoding the response body into text, so it has
// to be added again when the file is rebuilt on the client.
const UTF8_BOM = '\uFEFF';

export const downloadCsvFile = (fileName, content) => {
  const contentType = 'data:text/csv;charset=utf-8;';
  const text = `${content}`;
  const csvContent = text.startsWith(UTF8_BOM) ? text : `${UTF8_BOM}${text}`;
  const blob = new Blob([csvContent], { type: contentType });
  const url = URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.setAttribute('download', fileName);
  link.setAttribute('href', url);
  link.click();
  return link;
};

export const generateFileName = ({ type, to, businessHours = false }) => {
  let name = `${type}-report-${format(fromUnixTime(to), 'dd-MM-yyyy')}`;
  if (businessHours) {
    name = `${name}-business-hours`;
  }
  return `${name}.csv`;
};
