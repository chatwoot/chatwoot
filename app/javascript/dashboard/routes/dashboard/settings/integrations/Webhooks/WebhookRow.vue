<script setup>
import { computed } from 'vue';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  webhook: {
    type: Object,
    required: true,
  },
  index: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['edit', 'delete']);
const { t } = useI18n();
const subscribedEvents = computed(() => {
  const { subscriptions } = props.webhook;
  return subscriptions
    .map(event =>
      t(
        getI18nKey(
          'INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS',
          event
        )
      )
    )
    .join(', ');
});
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <div class="font-medium break-words text-slate-700 dark:text-slate-100">
        {{ webhook.url }}
      </div>
      <div class="block mt-1 text-sm text-slate-500 dark:text-slate-400">
        <span class="font-medium">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.SUBSCRIBED_EVENTS') }}:
        </span>
        <ShowMore :text="subscribedEvents" :limit="60" />
      </div>
    </td>
    <td class="py-4 min-w-xs">
      <div class="flex justify-end gap-1">
        <woot-button
          v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.BUTTON_TEXT')"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          icon="edit"
          @click="emit('edit', webhook)"
        />
        <woot-button
          v-tooltip.top="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')"
          variant="smooth"
          color-scheme="alert"
          size="tiny"
          icon="dismiss-circle"
          @click="emit('delete', webhook, index)"
        />
      </div>
    </td>
  </tr>
</template>
