export const CONVERSATION_EVENTS = Object.freeze({
  EXECUTED_A_MACRO: 'Executed a macro',
  SENT_MESSAGE: 'Sent a message',
  SENT_PRIVATE_NOTE: 'Sent a private note',
  INSERTED_A_CANNED_RESPONSE: 'Inserted a canned response',
  TRANSLATE_A_MESSAGE: 'Translated a message',
  INSERTED_A_VARIABLE: 'Inserted a variable',
  INSERTED_AN_EMOJI: 'Inserted an emoji',
  INSERTED_A_TOOL: 'Inserted a tool',
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

export const CAPTAIN_EVENTS = Object.freeze({
  // Editor funnel events
  EDITOR_AI_MENU_OPENED: 'Captain: Editor AI menu opened',
  GENERATION_FAILED: 'Captain: Generation failed',
  AI_ASSISTED_MESSAGE_SENT: 'Captain: AI-assisted message sent',

  // Rewrite events (with operation attribute in payload)
  REWRITE_USED: 'Captain: Rewrite used',
  REWRITE_APPLIED: 'Captain: Rewrite applied',
  REWRITE_DISMISSED: 'Captain: Rewrite dismissed',

  // Summarize events
  SUMMARIZE_USED: 'Captain: Summarize used',
  SUMMARIZE_APPLIED: 'Captain: Summarize applied',
  SUMMARIZE_DISMISSED: 'Captain: Summarize dismissed',

  // Reply suggestion events
  REPLY_SUGGESTION_USED: 'Captain: Reply suggestion used',
  REPLY_SUGGESTION_APPLIED: 'Captain: Reply suggestion applied',
  REPLY_SUGGESTION_DISMISSED: 'Captain: Reply suggestion dismissed',

  // Follow-up events
  FOLLOW_UP_SENT: 'Captain: Follow-up sent',

  // Label suggestions
  LABEL_SUGGESTION_APPLIED: 'Captain: Label suggestion applied',
  LABEL_SUGGESTION_DISMISSED: 'Captain: Label suggestion dismissed',
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

export const YEAR_IN_REVIEW_EVENTS = Object.freeze({
  MODAL_OPENED: 'Year in Review: Modal opened',
  NEXT_CLICKED: 'Year in Review: Next clicked',
  SHARE_CLICKED: 'Year in Review: Share clicked',
});
