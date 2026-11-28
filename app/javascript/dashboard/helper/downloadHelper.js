import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

const UTF8_BOM = '\uFEFF';

export const downloadCsvFile = (fileName, content) => {
  const contentType = 'data:text/csv;charset=utf-8;';
  const csvContent =
    typeof content === 'string' && !content.startsWith(UTF8_BOM)
      ? `${UTF8_BOM}${content}`
      : content;
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
