<template>
  <tr>
    <td>
      <div class="text-slate-700 dark:text-slate-100 font-medium break-words">
        {{ webhook.url }}
      </div>
      <span class="text-slate-500 dark:text-slate-400 text-xs">
        <span class="font-medium">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.SUBSCRIBED_EVENTS') }}:
        </span>
        <show-more :text="subscribedEvents" :limit="60" />
      </span>
    </td>
    <td class="max-w-[6.25rem] min-w-[auto] flex gap-3">
      <woot-button
        v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.BUTTON_TEXT')"
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        icon="edit"
        @click="$emit('edit', webhook)"
      />
      <woot-button
        v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        @click="$emit('delete', webhook, index)"
      />
    </td>
  </tr>
</template>
<script>
import webhookMixin from './webhookMixin';
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';

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
