export const CONVERSATION_EVENTS = Object.freeze({
  EXECUTED_A_MACRO: 'Executed a macro',
  SENT_MESSAGE: 'Sent a message',
  SENT_PRIVATE_NOTE: 'Sent a private note',
  INSERTED_A_CANNED_RESPONSE: 'Inserted a canned response',
  USED_MENTIONS: 'Used mentions',
});

export const ACCOUNT_EVENTS = Object.freeze({
  ADDED_TO_CANNED_RESPONSE: 'Used added to canned response option',
  ADDED_A_CUSTOM_ATTRIBUTE: 'Added a custom attribute',
  ADDED_AN_INBOX: 'Added an inbox',
});

export const LABEL_EVENTS = Object.freeze({
  CREATE: 'Created a label',
  UPDATE: 'Updated a label',
  DELETED: 'Deleted a label',
  APPLY_LABEL: 'Applied a label',
});

// REPORTS EVENTS
export const REPORTS_EVENTS = Object.freeze({
  DOWNLOAD_REPORT: 'Downloaded a report',
  FILTER_REPORT: 'Used filters in the reports',
});

// CONTACTS PAGE EVENTS
export const CONTACTS_EVENTS = Object.freeze({
  APPLY_FILTER: 'Applied filters in the contacts list',
  SAVE_FILTER: 'Saved a filter in the contacts list',
  DELETE_FILTER: 'Deleted a filter in the contacts list',

  APPLY_SORT: 'Sorted contacts list',
  SEARCH: 'Searched contacts list',
  CREATE_CONTACT: 'Created a contact',
  MERGED_CONTACTS: 'Used merge contact option',
  IMPORT_MODAL_OPEN: 'Opened import contacts modal',
  IMPORT_FAILURE: 'Import contacts failed',
  IMPORT_SUCCESS: 'Imported contacts successfully',
});

// CAMPAIGN EVENTS
export const CAMPAIGNS_EVENTS = Object.freeze({
  OPEN_NEW_CAMPAIGN_MODAL: 'Opened new campaign modal',
  CREATE_CAMPAIGN: 'Created a new campaign',
  UPDATE_CAMPAIGN: 'Updated a campaign',
  DELETE_CAMPAIGN: 'Deleted a campaign',
});

// PORTAL EVENTS
export const PORTALS_EVENTS = Object.freeze({
  ONBOARD_BASIC_INFORMATION: 'New Portal: Completed basic information',
  ONBOARD_CUSTOMIZATION: 'New portal: Completed customization',
  CREATE_PORTAL: 'Created a portal',
  DELETE_PORTAL: 'Deleted a portal',
  UPDATE_PORTAL: 'Updated a portal',

  CREATE_LOCALE: 'Created a portal locale',
  SET_DEFAULT_LOCALE: 'Set default portal locale',
  DELETE_LOCALE: 'Deleted a portal locale',
  SWITCH_LOCALE: 'Switched portal locale',

  CREATE_CATEGORY: 'Created a portal category',
  DELETE_CATEGORY: 'Deleted a portal category',
  EDIT_CATEGORY: 'Edited a portal category',

  CREATE_ARTICLE: 'Created an article',
  PUBLISH_ARTICLE: 'Published an article',
  ARCHIVE_ARTICLE: 'Archived an article',
  DELETE_ARTICLE: 'Deleted an article',
  PREVIEW_ARTICLE: 'Previewed article',
});
