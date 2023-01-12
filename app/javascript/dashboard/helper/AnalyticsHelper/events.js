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
  CREATE: 'Created a label',
  UPDATE: 'Updated a label',
  DELETED: 'Deleted a label',
  APPLY_LABEL: 'Applied a label',
};

// REPORTS EVENTS
export const REPORTS_EVENTS = {
  DOWNLOAD_REPORT: 'Downloaded a report',
  FILTER_REPORT: 'Filtered a report',
};

// CONTACTS PAGE EVENTS
export const CONTACTS_EVENTS = {
  APPLY_FILTER: 'Filtered contacts list',
  SAVE_FILTER: 'Saved a filter',
  DELETE_FILTER: 'Deleted a filter',

  APPLY_SORT: 'Sorted contacts list',
  SEARCH: 'Searched contacts list',
  CREATE_CONTACT: 'Created a contact',
  IMPORT_MODAL_OPEN: 'Opened import contacts modal',
  IMPORT_FAILURE: 'Import contacts failed',
  IMPORT_SUCCESS: 'Imported contacts',
};

// CAMPAIGN EVENTS
export const CAMPAIGNS_EVENTS = {
  OPEN_NEW_CAMPAIGN_MODAL: 'Opened new campaign modal',
  CREATE_CAMPAIGN: 'Created a campaign',
  UPDATE_CAMPAIGN: 'Updated a campaign',
  DELETE_CAMPAIGN: 'Deleted a campaign',
};

// PORTAL EVENTS
export const PORTALS_EVENTS = {
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
  UPDATE_ARTICLE_SETTINGS: 'Updated article settings',
  ARCHIVE_ARTICLE: 'Archived an article',
  DELETE_ARTICLE: 'Deleted an article',
  PREVIEW_ARTICLE: 'Previewed article',
};
