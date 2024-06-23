import { format } from 'date-fns';

export default {
  methods: {
    currentActionText(action) {
      if (!action) return '';
      const status = this.$t(
        'CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.' + action.status + '.TEXT'
      );
      const actionDate = action.snoozed_until || action.updated_at;
      const actionDateText = format(new Date(actionDate), 'dd/MM/yy');
      const actionText = `${action.inbox_type} / ${status}  (${actionDateText})`;
      if (action.additional_attributes.description)
        return `${action.additional_attributes.description} / ${actionText}`;

      return actionText;
    },
  },
};
