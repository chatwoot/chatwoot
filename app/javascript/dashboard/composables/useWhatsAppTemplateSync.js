import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { INBOX_TYPES, TWILIO_CHANNEL_MEDIUM } from 'dashboard/helper/inbox';

export function useWhatsAppTemplateSync() {
  const { t } = useI18n();
  const store = useStore();
  const inboxes = useMapGetter('inboxes/getInboxes');
  const isSyncing = ref(false);

  const whatsappInboxes = computed(() =>
    inboxes.value.filter(
      inbox =>
        inbox.channel_type === INBOX_TYPES.WHATSAPP ||
        (inbox.channel_type === INBOX_TYPES.TWILIO &&
          inbox.medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP)
    )
  );

  const canSync = computed(() => whatsappInboxes.value.length > 0);

  const syncTemplates = async () => {
    if (isSyncing.value || !canSync.value) return;

    isSyncing.value = true;

    const responses = await Promise.allSettled(
      whatsappInboxes.value.map(inbox =>
        store.dispatch('inboxes/syncTemplates', inbox.id)
      )
    );
    const failedCount = responses.filter(
      response => response.status === 'rejected'
    ).length;

    if (!failedCount) {
      useAlert(t('WHATSAPP_TEMPLATE_MGMT.SYNC_SUCCESS'));
    } else if (failedCount < responses.length) {
      useAlert(t('WHATSAPP_TEMPLATE_MGMT.PARTIAL_SYNC_ERROR'));
    } else {
      useAlert(t('WHATSAPP_TEMPLATE_MGMT.SYNC_ERROR'));
    }

    isSyncing.value = false;
  };

  return {
    isSyncing,
    canSync,
    whatsappInboxes,
    syncTemplates,
  };
}
