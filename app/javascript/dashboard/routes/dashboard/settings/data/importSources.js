export const IMPORT_SOURCES = [
  {
    value: 'intercom',
    label: 'Intercom',
    icon: '/dashboard/images/integrations/intercom.png',
  },
  {
    value: 'freshdesk',
    label: 'Freshdesk',
    iconClass: 'i-lucide-life-buoy',
    requiresDomain: true,
  },
];

export const importSourceConfigFor = provider =>
  IMPORT_SOURCES.find(source => source.value === provider);

const DEFAULT_IMPORT_SOURCE = {
  value: 'file',
  label: 'File import',
  iconClass: 'i-lucide-file-text',
};

export const importSourceFor = dataImport =>
  importSourceConfigFor(dataImport?.source_provider) || DEFAULT_IMPORT_SOURCE;
