import { format } from 'date-fns';

export default {
  methods: {
    currentConversationPlanText(conversation_plans) {
      if (!conversation_plans.length) return '';

      const latest_conversation_plan = conversation_plans[0];
      if (!latest_conversation_plan) return '';

      const {
        description,
        status,
        action_date: actionDate,
        inbox_type: inboxType,
      } = latest_conversation_plan;

      const status_text = this.$t(
        'CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.' + status + '.TEXT'
      );
      const actionDateText = format(new Date(actionDate), 'dd/MM/yy');
      const actionText = `${inboxType} / ${status_text}  (${actionDateText})`;
      if (description) return `${description} / ${actionText}`;

      return actionText;
    },
  },
};
