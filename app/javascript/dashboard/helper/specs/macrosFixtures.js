export const teams = [
  {
    id: 1,
    name: '⚙️ sales team',
    description: 'This is our internal sales team',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
  {
    id: 2,
    name: '🤷‍♂️ fayaz',
    description: 'Test',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
  {
    id: 3,
    name: '🇮🇳 apac sales',
    description: 'Sales team for France Territory',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
];

export const labels = [
  {
    id: 6,
    title: 'sales',
    description: 'sales team',
    color: '#8EA20F',
    show_on_sidebar: true,
  },
  {
    id: 2,
    title: 'billing',
    description: 'billing',
    color: '#4077DA',
    show_on_sidebar: true,
  },
  {
    id: 1,
    title: 'snoozed',
    description: 'Items marked for later',
    color: '#D12F42',
    show_on_sidebar: true,
  },
  {
    id: 5,
    title: 'mobile-app',
    description: 'tech team',
    color: '#2DB1CC',
    show_on_sidebar: true,
  },
  {
    id: 14,
    title: 'human-resources-department-with-long-title',
    description: 'Test',
    color: '#FF6E09',
    show_on_sidebar: true,
  },
  {
    id: 22,
    title: 'priority',
    description: 'For important sales leads',
    color: '#7E7CED',
    show_on_sidebar: true,
  },
];

export const agents = [
  {
    id: 1,
    account_id: 1,
    availability_status: 'offline',
    auto_offline: true,
    confirmed: true,
    email: 'john@doe.com',
    available_name: 'John Doe',
    name: 'John Doe',
    role: 'agent',
    thumbnail:
      'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--746506837470c1a3dd063e90211ba2386963d52f/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/batman_90804.png',
  },
  {
    id: 9,
    account_id: 1,
    availability_status: 'offline',
    auto_offline: true,
    confirmed: true,
    email: 'clark@kent.com',
    available_name: 'Clark Kent',
    name: 'Clark Kent',
    role: 'agent',
    thumbnail: '',
  },
];

export const files = [
  {
    id: 76,
    macro_id: 77,
    file_type: 'image/jpeg',
    account_id: 1,
    file_url:
      'http://localhost:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBYUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--aa41b5a779a83c1d86b28475a5cf0bd17f41f0ff/fayaz_cropped.jpeg',
    blob_id: 88,
    filename: 'fayaz_cropped.jpeg',
  },
  {
    id: 82,
    macro_id: 77,
    file_type: 'image/png',
    account_id: 1,
    file_url:
      'http://localhost:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBZdz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--260fda80b77409ffaaac10b96681fba447600545/screenshot.png',
    blob_id: 94,
    filename: 'screenshot.png',
  },
];
