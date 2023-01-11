// CONVERSATION EVENTS
export const EXECUTED_A_MACRO = 'Executed a macro';
export const SENT_MESSAGE = 'Sent a message';
export const SENT_PRIVATE_NOTE = 'Sent a private note';
export const INSERTED_A_CANNED_RESPONSE = 'Inserted a canned response';
export const USED_MENTIONS = 'Used mentions';
export const MERGED_CONTACTS = 'Used merge contact option';
export const ADDED_TO_CANNED_RESPONSE = 'Used added to canned response option';
export const ADDED_A_CUSTOM_ATTRIBUTE = 'Added a custom attribute';
export const ADDED_AN_INBOX = 'Added an inbox';

// REPORTS EVENTS
export const REPORTS = {
  DOWNLOAD_REPORT: 'Downloaded a report',
  FILTERED_REPORT: 'Filtered a report',
  BUSINESS_HOUR_TOGGLE: 'Business hour toggle',
};

// CONTACTS PAGE EVENTS
export const CONTACTS = {
  APPLY_FILTER: 'Filter contacts list',
  APPLY_SORT: 'Sort contacts list',
  SEARCH: 'Search contacts list',
  IMPORT_MODAL_OPEN: 'Open import contacts modal',
  IMPORT_FAILURE: 'Import contacts failed',
  IMPORT_SUCCESS: 'Import contacts success',
  NEW_CONTACT_LABEL: 'Created a new contact label',
};

// CAMPAIGN EVENTS
export const CAMPAIGNS = {
  OPEN_NEW_CAMPAIGN_MODAL: 'Open new campaign modal',
  CREATE_CAMPAIGN: 'Create new campaign',
  EDIT_CAMPAIGN: 'Edit ongoing campaign',
  DELETE_CAMPAIGN: 'Delete ongoing campaign',
};

// PORTAL EVENTS
export const PORTALS = {
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

export const ANALYTICS_EVENTS = {
  REPORTS,
  CONTACTS,
  CAMPAIGNS,
  PORTALS,
  CONVERSATION: {
    EXECUTED_A_MACRO,
    SENT_MESSAGE,
    SENT_PRIVATE_NOTE,
    INSERTED_A_CANNED_RESPONSE,
    USED_MENTIONS,
    MERGED_CONTACTS,
    ADDED_TO_CANNED_RESPONSE,
    ADDED_A_CUSTOM_ATTRIBUTE,
    ADDED_AN_INBOX,
  },
};
