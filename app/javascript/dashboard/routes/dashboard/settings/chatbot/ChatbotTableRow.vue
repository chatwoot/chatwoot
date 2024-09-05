<template>
  <tr>
    <td>{{ chatbot.name }}</td>
    <td>{{ chatbot.status }}</td>
    <td>{{ chatbot.last_trained_at }}</td>
    <td class="button-wrapper">
      <router-link :to="addAccountScoping(`settings/chatbots/${chatbot.id}`)">
        <woot-button
          v-tooltip.top="$t('CHATBOTS.SETTINGS')"
          :disabled="!canEdit"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          class-names="grey-btn"
          icon="settings"
        />
      </router-link>
      <woot-button
        v-if="isAdmin"
        v-tooltip.top="$t('CHATBOTS.DELETE.TOOLTIP')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        class-names="grey-btn"
        @click="$emit('delete')"
      />
    </td>
  </tr>
</template>

<script>
import accountMixin from 'dashboard/mixins/account.js';
import adminMixin from '../../../../mixins/isAdmin';
export default {
  mixins: [adminMixin, accountMixin],
  props: {
    chatbot: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canEdit() {
      return (
        this.chatbot.status !== 'Creating' ||
        this.chatbot.status !== 'Retraining'
      );
    },
  },
};
</script>
