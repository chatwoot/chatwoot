// Groups Copilot's built-in tools for admins. The tools themselves are Captain::Copilot::TurnService::TOOLS and
// WORKFLOW_TOOLS; update these groups when that list changes.
export const COPILOT_BUILT_IN_TOOL_GROUPS = [
  {
    // get_conversation, get_contact, search_contacts, get_report, get_account_directory, get_data,
    // review_conversations, continue_review, display, act
    key: 'CONVERSATIONS',
    icon: 'i-lucide-messages-square',
  },
  {
    // search_articles, get_article
    key: 'ARTICLES',
    icon: 'i-lucide-library-big',
  },
  {
    // search_documentation
    key: 'FAQS',
    icon: 'i-lucide-book-open',
  },
  {
    // search_linear_issues, offered only when the account has the Linear integration
    key: 'LINEAR',
    integrationId: 'linear',
  },
];

// An assistant saved on or off keeps that choice. Any other assistant follows "Include new assistants automatically",
// which is on when it was never saved.
export const isAssistantSearched = (settings, assistantId) => {
  if (settings.assistant_ids?.includes(assistantId)) return true;
  if (settings.excluded_assistant_ids?.includes(assistantId)) return false;
  return settings.include_new_assistants !== false;
};
