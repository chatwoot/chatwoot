<template>
  <tr>
    <td>
      <div class="webhook--link">{{ webhook.url }}</div>
      <span class="webhook--subscribed-events">
        <span class="webhook--subscribed-label">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.SUBSCRIBED_EVENTS') }}:
        </span>
        <show-more :text="subscribedEvents" :limit="60" />
      </span>
    </td>
    <td class="button-wrapper">
      <woot-button
        v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.BUTTON_TEXT')"
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        icon="edit"
        @click="$emit('edit', webhook)"
      >
      </woot-button>
      <woot-button
        v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        @click="$emit('delete', webhook, index)"
      >
      </woot-button>
    </td>
  </tr>
</template>
<script>
import webhookMixin from './webhookMixin';
import ShowMore from 'dashboard/components/widgets/ShowMore';

export default {
  components: { ShowMore },
  mixins: [webhookMixin],
  props: {
    webhook: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    subscribedEvents() {
      const { subscriptions } = this.webhook;
      return subscriptions.map(event => this.getEventLabel(event)).join(', ');
    },
  },
};
</script>
<style scoped lang="scss">
.webhook--link {
  color: var(--s-700);
  font-weight: var(--font-weight-medium);
  word-break: break-word;
}

.webhook--subscribed-events {
  color: var(--s-500);
  font-size: var(--font-size-mini);
}

.webhook--subscribed-label {
  font-weight: var(--font-weight-medium);
}

.button-wrapper {
  max-width: var(--space-mega);
  min-width: auto;

  button:nth-child(2) {
    margin-left: var(--space-normal);
  }
}
</style>
