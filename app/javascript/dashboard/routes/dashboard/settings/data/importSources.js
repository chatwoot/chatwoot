export const IMPORT_SOURCES = [
  {
    value: 'intercom',
    label: 'Intercom',
    icon: '/dashboard/images/integrations/intercom.png',
  },
];

const DEFAULT_IMPORT_SOURCE = {
  value: 'file',
  label: 'File import',
  iconClass: 'i-lucide-file-text',
};

export const importSourceFor = dataImport =>
  IMPORT_SOURCES.find(source => source.value === dataImport?.source_provider) ||
  DEFAULT_IMPORT_SOURCE;
