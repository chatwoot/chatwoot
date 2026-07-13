export const POLL_INTERVAL_MS = 5000;

export const ACTIVE_IMPORT_STATUSES = ['pending', 'processing'];

export const isActiveImport = dataImport =>
  ACTIVE_IMPORT_STATUSES.includes(dataImport?.status);

export const isIntercomImport = dataImport =>
  dataImport?.data_type === 'intercom' &&
  dataImport?.source_provider === 'intercom';

export const isActiveIntercomImport = dataImport =>
  isIntercomImport(dataImport) && isActiveImport(dataImport);

export const isAbandonableImport = dataImport =>
  isActiveIntercomImport(dataImport);

export const importedCount = dataImport => {
  if (!isIntercomImport(dataImport)) {
    return Number(dataImport?.processed_records || 0);
  }

  return ['contacts', 'conversations', 'messages'].reduce(
    (total, key) => total + Number(dataImport?.stats?.[key]?.imported || 0),
    0
  );
};

export const importStageKey = dataImport => {
  if (!dataImport) return 'unknown';

  if (dataImport.status === 'completed') return 'completed';
  if (dataImport.status === 'completed_with_errors') {
    return 'completed_with_errors';
  }
  if (dataImport.status === 'failed') return 'failed';
  if (dataImport.status === 'abandoned') return 'abandoned';
  if (dataImport.status === 'pending') return 'queued';

  const importTypes = dataImport.import_types?.length
    ? dataImport.import_types
    : [dataImport.data_type];
  const cursor = dataImport.cursor || {};

  if (importTypes.includes('contacts') && !cursor.contacts?.completed) {
    return 'contacts';
  }

  if (
    importTypes.includes('conversations') &&
    !cursor.conversations?.completed
  ) {
    return 'conversations';
  }

  return 'finalizing';
};

export const formatStatus = value => value?.replaceAll('_', ' ') || '-';

export const sourceObjectLabel = record =>
  [record.source_object_type, record.source_object_id]
    .filter(Boolean)
    .join(': ') || '-';

export const formatDate = value => {
  if (!value) return '-';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
};

const STATUS_DOT_CLASS = {
  pending: 'bg-n-amber-9',
  processing: 'bg-n-blue-9',
  completed: 'bg-n-teal-9',
  completed_with_errors: 'bg-n-amber-9',
  failed: 'bg-n-ruby-9',
  abandoned: 'bg-n-slate-9',
};

export const statusDotClass = status =>
  STATUS_DOT_CLASS[status] || 'bg-n-slate-9';
