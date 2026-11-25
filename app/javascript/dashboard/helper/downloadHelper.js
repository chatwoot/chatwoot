import fromUnixTime from 'date-fns/fromUnixTime';
import { formatFixed } from 'shared/helpers/localizedDate';

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

// Readable half of the filter suffix. Drops to an empty string for a name
// written outside the Latin alphabet, which is why the id carries the identity.
const slugifyFilterName = name =>
  name
    .toString()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

// Keeps the same report downloaded for two different filters in two files. Two
// agents can share a display name, so the id is what makes the pair distinct
// and the name is only there to make the file recognizable.
const buildFilterSuffix = (filteredBy, filterId) => {
  const id =
    filterId === null || filterId === undefined ? '' : String(filterId);
  const slug = filteredBy ? slugifyFilterName(filteredBy) : '';
  return [slug, id].filter(part => part !== '').join('-');
};

export const generateFileName = ({
  type,
  to,
  businessHours = false,
  filteredBy = '',
  filterId = '',
}) => {
  let name = `${type}-report-${formatFixed(fromUnixTime(to), 'dd-MM-yyyy')}`;
  const filterSuffix = buildFilterSuffix(filteredBy, filterId);
  if (filterSuffix) {
    name = `${name}-${filterSuffix}`;
  }
  if (businessHours) {
    name = `${name}-business-hours`;
  }
  return `${name}.csv`;
};
