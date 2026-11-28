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

// Copilot searches the FAQs of one assistant. A saved null means none. Accounts that never saved this page, or whose
// saved assistant was deleted, get the first assistant in the list, which is also Copilot's last fallback today.
export const findSearchedAssistant = (settings, assistants) => {
  if (settings.assistant_id === null) return null;
  return (
    assistants.find(assistant => assistant.id === settings.assistant_id) ||
    assistants[0] ||
    null
  );
};
