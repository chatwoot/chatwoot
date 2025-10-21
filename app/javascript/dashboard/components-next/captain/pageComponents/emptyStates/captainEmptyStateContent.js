import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const assistantsList = [
  {
    account_id: 2,
    config: { product_name: 'HelpDesk Pro' },
    created_at: 1736033561,
    description:
      'An advanced AI assistant designed to enhance customer support solutions by automating workflows and providing instant responses.',
    id: 4,
    name: 'Support Genie',
  },
  {
    account_id: 3,
    config: { product_name: 'CRM Tools' },
    created_at: 1736033562,
    description:
      'Helps streamline customer relationship management by organizing contacts, automating follow-ups, and providing insights.',
    id: 5,
    name: 'CRM Assistant',
  },
  {
    account_id: 4,
    config: { product_name: 'SalesFlow' },
    created_at: 1736033563,
    description:
      'Optimizes your sales pipeline by tracking prospects, forecasting sales, and automating administrative tasks.',
    id: 6,
    name: 'SalesBot',
  },
  {
    account_id: 5,
    config: { product_name: 'TicketMaster AI' },
    created_at: 1736033564,
    description:
      'Automates ticket assignment, categorization, and customer query responses to enhance support efficiency.',
    id: 7,
    name: 'TicketBot',
  },
  {
    account_id: 6,
    config: { product_name: 'FinanceAssist' },
    created_at: 1736033565,
    description:
      'Provides financial analytics, reporting, and insights, helping teams make data-driven financial decisions.',
    id: 8,
    name: 'Finance Wizard',
  },
  {
    account_id: 8,
    config: { product_name: 'HR Assistant' },
    created_at: 1736033567,
    description:
      'Streamlines HR operations including employee management, payroll, and recruitment processes.',
    id: 10,
    name: 'HR Helper',
  },
];

export const documentsList = [
  {
    account_id: 1,
    assistant: { id: 1, name: 'Helper Pro' },
    content:
      'Comprehensive guide on using conversation filters to manage chats effectively.',
    created_at: 1736143272,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688192-how-to-use-conversation-filters',
    id: 3059,
    name: 'How to use Conversation Filters? | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 2,
    assistant: { id: 2, name: 'Support Genie' },
    content:
      'Step-by-step guide for automating ticket assignments and improving support workflow in Chatwoot.',
    created_at: 1736143273,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688200-automating-ticket-assignments',
    id: 3060,
    name: 'Automating Ticket Assignments | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 3,
    assistant: { id: 3, name: 'CRM Assistant' },
    content:
      'A detailed guide on managing and organizing customer profiles for better relationship management.',
    created_at: 1736143274,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688210-managing-customer-profiles',
    id: 3061,
    name: 'Managing Customer Profiles | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 4,
    assistant: { id: 4, name: 'SalesBot' },
    content:
      'Learn how to optimize sales tracking and improve your sales forecasting using advanced features.',
    created_at: 1736143275,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688220-sales-tracking-guide',
    id: 3062,
    name: 'Sales Tracking Guide | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 5,
    assistant: { id: 5, name: 'TicketBot' },
    content:
      'How to efficiently create, manage, and resolve tickets in Chatwoot.',
    created_at: 1736143276,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688230-managing-tickets',
    id: 3063,
    name: 'Managing Tickets | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 6,
    assistant: { id: 6, name: 'Finance Wizard' },
    content:
      'Detailed guide on how to use financial reporting tools and generate insightful analytics.',
    created_at: 1736143277,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688240-financial-reporting',
    id: 3064,
    name: 'Financial Reporting | User Guide | Chatwoot',
    status: 'available',
  },
];

export const responsesList = [
  {
    account_id: 1,
    answer:
      'Messenger may be deactivated because you are on a free plan or the limit for inboxes might have been reached.',
    created_at: 1736283330,
    id: 87,
    question: 'Why is my Messenger in Chatwoot deactivated?',
    status: 'pending',
    assistant: {
      account_id: 1,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033280,
      description: 'Assists with general queries and system-wide issues.',
      id: 1,
      name: 'Assistant 2',
    },
  },
  {
    account_id: 2,
    answer:
      'You can integrate your WhatsApp account by navigating to the Integrations section and selecting the WhatsApp integration option.',
    created_at: 1736283340,
    id: 88,
    question: 'How do I integrate WhatsApp with Chatwoot?',
    assistant: {
      account_id: 2,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033281,
      description: 'Helps with integration and setup-related inquiries.',
      id: 2,
      name: 'Assistant 3',
    },
  },
  {
    account_id: 3,
    answer:
      "To reset your password, go to the login page and click on 'Forgot Password', then follow the instructions sent to your email.",
    created_at: 1736283350,
    id: 89,
    question: 'How can I reset my password in Chatwoot?',
    assistant: {
      account_id: 3,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033282,
      description: 'Handles account management and recovery support.',
      id: 3,
      name: 'Assistant 4',
    },
  },
  {
    account_id: 4,
    answer:
      "You can enable the dark mode in settings by navigating to 'Appearance' and selecting 'Dark Mode'.",
    created_at: 1736283360,
    id: 90,
    question: 'How do I enable dark mode in Chatwoot?',
    assistant: {
      account_id: 4,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033283,
      description: 'Helps with UI and theme-related inquiries.',
      id: 4,
      name: 'Assistant 5',
    },
  },
  {
    account_id: 5,
    answer:
      "To add a new team member, navigate to 'Settings', then 'Team', and click on 'Add Team Member'.",
    created_at: 1736283370,
    id: 91,
    question: 'How do I add a new team member in Chatwoot?',
    assistant: {
      account_id: 5,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033284,
      description: 'Supports team management and user access-related queries.',
      id: 5,
      name: 'Assistant 6',
    },
  },
  {
    account_id: 6,
    answer:
      "Campaigns in Chatwoot allow you to send targeted messages to specific user segments. You can create them in the 'Campaigns' section.",
    created_at: 1736283380,
    id: 92,
    question: 'What are campaigns in Chatwoot?',
    assistant: {
      account_id: 6,
      config: { product_name: 'Chatwoot' },
      created_at: 1736033285,
      description:
        'Specialized in marketing, campaign management, and messaging strategies.',
      id: 6,
      name: 'Assistant 7',
    },
  },
];

export const inboxes = [
  {
    id: 7,
    name: 'Email Support',
    channel_type: INBOX_TYPES.EMAIL,
    email: 'support@company.com',
  },
  {
    id: 1,
    name: 'Website Chat',
    channel_type: INBOX_TYPES.WEB,
  },
  {
    id: 2,
    name: 'Facebook Support',
    channel_type: INBOX_TYPES.FB,
  },
  {
    id: 5,
    name: 'SMS Service',
    channel_type: INBOX_TYPES.TWILIO,
    messaging_service_sid: 'MGxxxxxx',
  },
  {
    id: 6,
    name: 'WhatsApp Support',
    channel_type: INBOX_TYPES.WHATSAPP,
    phone_number: '+1987654321',
  },
  {
    id: 8,
    name: 'Telegram Support',
    channel_type: INBOX_TYPES.TELEGRAM,
  },
  {
    id: 9,
    name: 'LINE Support',
    channel_type: INBOX_TYPES.LINE,
  },
  {
    id: 10,
    name: 'API Channel',
    channel_type: INBOX_TYPES.API,
  },
  {
    id: 11,
    name: 'SMS Basic',
    channel_type: INBOX_TYPES.SMS,
    phone_number: '+1555555555',
  },
];
