export default {
  methods: {
    getDropdownValues(type) {
      switch (type) {
        case 'assign_team':
        case 'send_email_to_team':
          return this.teams;
        case 'add_label':
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
