import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

const XLSX_MIME =
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

export const downloadCsvFile = (fileName, content) => {
  const contentType = 'data:text/csv;charset=utf-8;';
  const blob = new Blob([content], { type: contentType });
  const url = URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.setAttribute('download', fileName);
  link.setAttribute('href', url);
  link.click();
  return link;
};

export const downloadFile = (fileName, content) => {
  const isXlsx = fileName.endsWith('.xlsx');
  if (!isXlsx) {
    return downloadCsvFile(fileName, content);
  }

  const blob =
    content instanceof Blob
      ? content
      : new Blob([content], { type: XLSX_MIME });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('download', fileName);
  link.setAttribute('href', url);
  link.click();
  URL.revokeObjectURL(url);
  return link;
};

export const generateFileName = ({
  type,
  to,
  businessHours = false,
  format: fileFormat = 'csv',
}) => {
  let name = `${type}-report-${format(fromUnixTime(to), 'dd-MM-yyyy')}`;
  if (businessHours) {
    name = `${name}-business-hours`;
  }
  const extension = fileFormat === 'xlsx' ? 'xlsx' : 'csv';
  return `${name}.${extension}`;
};
