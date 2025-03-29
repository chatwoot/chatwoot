export const CONVERSATION_EVENTS = Object.freeze({
  EXECUTED_A_MACRO: 'Executed a macro',
  SENT_MESSAGE: 'Sent a message',
  SENT_PRIVATE_NOTE: 'Sent a private note',
  INSERTED_A_CANNED_RESPONSE: 'Inserted a canned response',
  TRANSLATE_A_MESSAGE: 'Translated a message',
  INSERTED_A_VARIABLE: 'Inserted a variable',
  INSERTED_AN_EMOJI: 'Inserted an emoji',
  USED_MENTIONS: 'Used mentions',
  SEARCH_CONVERSATION: 'Searched conversations',
  APPLY_FILTER: 'Applied filters in the conversation list',
  CHANGE_PRIORITY: 'Assigned priority to a conversation',
  INSERT_ARTICLE_LINK: 'Inserted article into reply via article search',
});

export const ACCOUNT_EVENTS = Object.freeze({
  ADDED_TO_CANNED_RESPONSE: 'Used added to canned response option',
  ADDED_A_CUSTOM_ATTRIBUTE: 'Added a custom attribute',
  ADDED_AN_INBOX: 'Added an inbox',
  OPEN_MESSAGE_CONTEXT_MENU: 'Opened message context menu',
  OPENED_NOTIFICATIONS: 'Opened notifications',
  MARK_AS_READ_NOTIFICATIONS: 'Marked notifications as read',
  OPEN_CONVERSATION_VIA_NOTIFICATION: 'Opened conversation via notification',
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

export const OPEN_AI_EVENTS = Object.freeze({
  SUMMARIZE: 'OpenAI: Used summarize',
  REPLY_SUGGESTION: 'OpenAI: Used reply suggestion',
  REPHRASE: 'OpenAI: Used rephrase',
  FIX_SPELLING_AND_GRAMMAR: 'OpenAI: Used fix spelling and grammar',
  SHORTEN: 'OpenAI: Used shorten',
  EXPAND: 'OpenAI: Used expand',
  MAKE_FRIENDLY: 'OpenAI: Used make friendly',
  MAKE_FORMAL: 'OpenAI: Used make formal',
  SIMPLIFY: 'OpenAI: Used simplify',
  APPLY_LABEL_SUGGESTION: 'OpenAI: Apply label from suggestion',
  DISMISS_LABEL_SUGGESTION: 'OpenAI: Dismiss label suggestions',
  ADDED_AI_INTEGRATION_VIA_CTA_BUTTON:
    'OpenAI: Added AI integration via CTA button',
  DISMISS_AI_SUGGESTION: 'OpenAI: Dismiss AI suggestions',
});

export const COPILOT_EVENTS = Object.freeze({
  SEND_SUGGESTED: 'Copilot: Send suggested message',
  SEND_MESSAGE: 'Copilot: Sent a message',
  USE_CAPTAIN_RESPONSE: 'Copilot: Used captain response',
});

export const GENERAL_EVENTS = Object.freeze({
  COMMAND_BAR: 'Used commandbar',
});

export const INBOX_EVENTS = Object.freeze({
  OPEN_CONVERSATION_VIA_INBOX: 'Opened conversation via inbox',
  MARK_NOTIFICATION_AS_READ: 'Marked notification as read',
  MARK_ALL_NOTIFICATIONS_AS_READ: 'Marked all notifications as read',
  MARK_NOTIFICATION_AS_UNREAD: 'Marked notification as unread',
  DELETE_NOTIFICATION: 'Deleted notification',
  DELETE_ALL_NOTIFICATIONS: 'Deleted all notifications',
});

export const SLA_EVENTS = Object.freeze({
  CREATE: 'Created an SLA',
  UPDATE: 'Updated an SLA',
  DELETED: 'Deleted an SLA',
});

export const LINEAR_EVENTS = Object.freeze({
  CREATE_ISSUE: 'Created a linear issue',
  LINK_ISSUE: 'Linked a linear issue',
  UNLINK_ISSUE: 'Unlinked a linear issue',
});
