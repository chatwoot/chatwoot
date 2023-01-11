// CONVERSATION EVENTS
export const CONVERSATION_EVENTS = {
  EXECUTED_A_MACRO: 'Executed a macro',
  SENT_MESSAGE: 'Sent a message',
  SENT_PRIVATE_NOTE: 'Sent a private note',
  INSERTED_A_CANNED_RESPONSE: 'Inserted a canned response',
  USED_MENTIONS: 'Used mentions',
  MERGED_CONTACTS: 'Used merge contact option',
  ADDED_TO_CANNED_RESPONSE: 'Used added to canned response option',
  ADDED_A_CUSTOM_ATTRIBUTE: 'Added a custom attribute',
  ADDED_AN_INBOX: 'Added an inbox',
};

export const LABEL_EVENTS = {
  CREATE: 'Created a new label',
  UPDATE: 'Updated a label',
  DELETED: 'Deleted a label',
  APPLY_LABEL: 'Apply a label',
};

// REPORTS EVENTS
export const REPORTS_EVENTS = {
  DOWNLOAD_REPORT: 'Downloaded a report',
  FILTER_REPORT: 'Filtered a report',
};

// CONTACTS PAGE EVENTS
export const CONTACTS_EVENTS = {
  APPLY_FILTER: 'Filter contacts list',
  APPLY_SORT: 'Sort contacts list',
  SEARCH: 'Search contacts list',
  IMPORT_MODAL_OPEN: 'Open import contacts modal',
  IMPORT_FAILURE: 'Import contacts failed',
  IMPORT_SUCCESS: 'Import contacts success',
};

// CAMPAIGN EVENTS
export const CAMPAIGNS_EVENTS = {
  OPEN_NEW_CAMPAIGN_MODAL: 'Open new campaign modal',
  CREATE_CAMPAIGN: 'Create new campaign',
  EDIT_CAMPAIGN: 'Edit ongoing campaign',
  DELETE_CAMPAIGN: 'Delete ongoing campaign',
};

// PORTAL EVENTS
export const PORTALS_EVENTS = {
  CREATE_PORTAL: 'Create a new portal',
  DELETE_PORTAL: 'Delete a portal',
  PREVIEW_PORTAL: 'Preview a portal',
  UPDATE_PORTAL: 'Update a portal',

  CREATE_LOCALE: 'Create a new locale',
  SET_DEFAULT_LOCALE: 'Set default locale',
  DELETE_LOCALE: 'Delete a locale',
  SWITCH_LOCALE: 'Switch locale',

  CREATE_CATEGORY: 'Create a new category',
  DELETE_CATEGORY: 'Delete a category',
  EDIT_CATEGORY: 'Edit a category',

  CREATE_ARTICLE: 'Create a new article',
  PUBLISH_ARTICLE: 'Publish an article',
  UPDATE_ARTICLE_SETTINGS: 'Update article settings',
  ARCHIVE_ARTICLE: 'Archive an article',
  DELETE_ARTICLE: 'Delete an article',
  PREVIEW_ARTICLE: 'Preview article',
};
