<template>
  <tr>
    <td>{{ chatbot.name }}</td>
    <td>{{ chatbot.status }}</td>
    <td>{{ chatbot.last_trained_at }}</td>
    <td class="button-wrapper">
      <router-link
        :to="
          addAccountScoping(
            `settings/chatbot/edit/${chatbot.id}@${chatbot.last_trained_at}`
          )
        "
      >
        <woot-button
          v-tooltip.top="$t('CHATBOTS.EDIT.TOOLTIP')"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          class-names="grey-btn"
          icon="edit"
        />
      </router-link>
      <woot-button
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
export default {
  mixins: [accountMixin],
  props: {
    chatbot: {
      type: Object,
      required: true,
    },
  },
};
</script>
