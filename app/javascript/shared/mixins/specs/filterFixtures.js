export const filterGroups = [
  {
    name: 'Standard Filters',
    attributes: [
      { key: 'status', name: 'Status' },
      { key: 'assignee_id', name: 'Assignee Name' },
      { key: 'inbox_id', name: 'Inbox Name' },
      { key: 'team_id', name: 'Team Name' },
      { key: 'display_id', name: 'Conversation Identifier' },
      { key: 'campaign_id', name: 'Campaign Name' },
      { key: 'labels', name: 'Labels' },
    ],
  },
  {
    name: 'Additional Filters',
    attributes: [
      { key: 'browser_language', name: 'Browser Language' },
      { key: 'country_code', name: 'Country Name' },
      { key: 'referer', name: 'Referer link' },
    ],
  },
  {
    name: 'Custom Attributes',
    attributes: [
      { key: 'signed_up_at', name: 'Signed Up At' },
      { key: 'test', name: 'Test' },
    ],
  },
];
