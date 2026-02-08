export default [
  {
    id: 22,
    name: 'Assign billing label and sales team and message user',
    visibility: 'global',
    created_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    updated_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    account_id: 1,
    actions: [
      {
        action_name: 'add_label',
        action_params: ['sales', 'billing'],
      },
      {
        action_name: 'assign_team',
        action_params: [1],
      },
      {
        action_name: 'send_message',
        action_params: [
          "Thank you for reaching out, we're looking into this on priority and we'll get back to you asap.",
        ],
      },
    ],
  },
  {
    id: 23,
    name: 'Assign label priority and send email to team',
    visibility: 'global',
    created_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    updated_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    account_id: 1,
    actions: [
      {
        action_name: 'add_label',
        action_params: ['priority'],
      },
      {
        action_name: 'send_email_to_team',
        action_params: [
          {
            message: 'Hello team,\n\nThis looks important, please take look.',
            team_ids: [1],
          },
        ],
      },
    ],
  },
  {
    id: 25,
    name: 'Webhook',
    visibility: 'global',
    created_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    updated_by: {
      id: 1,
      account_id: 1,
      availability_status: 'online',
      auto_offline: true,
      confirmed: true,
      email: 'john@acme.inc',
      available_name: 'Fayaz Ahmed',
      name: 'Fayaz Ahmed',
      role: 'administrator',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--16c85844c93f9c139deb782137b49c87c9bc871c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/memoji.png',
    },
    account_id: 1,
    actions: [
      {
        action_name: 'send_webhook_event',
        action_params: ['https://google.com'],
      },
    ],
  },
];
