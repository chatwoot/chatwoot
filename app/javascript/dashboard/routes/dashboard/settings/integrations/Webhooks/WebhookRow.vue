<template>
  <tr class="space-x-2">
    <td class="max-w-2xl">
      <div class="font-medium break-words text-slate-700 dark:text-slate-100">
        {{ webhook.url }}
      </div>
      <span class="text-xs text-slate-500 dark:text-slate-400">
        <span class="font-medium">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.SUBSCRIBED_EVENTS') }}:
        </span>
        <show-more :text="subscribedEvents" :limit="60" />
      </span>
    </td>
    <td class="min-w-[7rem] flex gap-1 justify-end flex-shrink-0">
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
