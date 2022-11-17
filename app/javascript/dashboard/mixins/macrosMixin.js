export default {
  methods: {
    getDropdownValues(type) {
      switch (type) {
        case 'assign_team':
        case 'send_email_to_team':
          return this.teams;
        case 'assign_agent':
          return this.agents;
        case 'add_label':
        case 'remove_label':
          return this.labels.map(i => {
            return {
              id: i.title,
              name: i.title,
            };
          });
        default:
          return [];
      }
    },
  },
};
