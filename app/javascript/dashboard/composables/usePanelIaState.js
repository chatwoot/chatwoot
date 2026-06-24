import { computed, unref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { isBotHandledConversation } from 'dashboard/helper/assigneeHelper';

const STATE_CONFIG = {
  activo: {
    indicatorClass: 'bg-n-teal-9',
    i18nKey: 'PANEL_IA_STATE_ACTIVE',
  },
  esperando: {
    indicatorClass: 'bg-n-amber-9',
    i18nKey: 'PANEL_IA_STATE_WAITING',
  },
  solicita_ayuda: {
    indicatorClass: 'bg-n-ruby-9',
    i18nKey: 'PANEL_IA_STATE_HELP',
    pulseIndicator: true,
  },
};

export function usePanelIaState(chatRef) {
  const { t } = useI18n();

  const isBotHandled = computed(() => isBotHandledConversation(unref(chatRef)));

  const state = computed(() => {
    const chat = unref(chatRef);
    const estado = chat?.custom_attributes?.panel_ia_estado;
    if (estado) return estado;
    return isBotHandled.value ? 'activo' : '';
  });

  const showIndicator = computed(
    () => isBotHandled.value && Boolean(STATE_CONFIG[state.value])
  );

  const config = computed(() => STATE_CONFIG[state.value] || null);

  const label = computed(() => {
    const chat = unref(chatRef);
    const customLabel = chat?.custom_attributes?.panel_ia_estado_label;
    if (customLabel) return customLabel;
    if (!config.value) return '';
    return t(`CONVERSATION.${config.value.i18nKey}`);
  });

  const indicatorClass = computed(() => {
    if (!showIndicator.value || !config.value) return '';
    return config.value.indicatorClass;
  });

  // #region agent log
  watch(
    () => {
      const chat = unref(chatRef);
      return [
        chat?.id,
        chat?.custom_attributes?.panel_ia_estado,
        chat?.meta?.assignee_type,
        chat?.meta?.assignee?.id,
        chat?.bot_handling,
        isBotHandled.value,
        state.value,
        showIndicator.value,
      ];
    },
    () => {
      const chat = unref(chatRef);
      if (!chat?.id) return;
      fetch('http://127.0.0.1:7681/ingest/5a14c770-9960-4aff-80cb-467e93b61e93', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'b893f4',
        },
        body: JSON.stringify({
          sessionId: 'b893f4',
          runId: 'panel-ia-strip-fix',
          hypothesisId: 'I',
          location: 'usePanelIaState.js:watch',
          message: 'panel ia strip state',
          data: {
            conversationId: chat.id,
            panelIaEstado: chat.custom_attributes?.panel_ia_estado ?? null,
            assigneeType: chat.meta?.assignee_type ?? null,
            assigneeId: chat.meta?.assignee?.id ?? null,
            botHandling: chat.bot_handling ?? null,
            isBotHandled: isBotHandled.value,
            resolvedState: state.value,
            showIndicator: showIndicator.value,
          },
          timestamp: Date.now(),
        }),
      }).catch(() => {});
    },
    { immediate: true }
  );
  // #endregion

  return {
    state,
    showIndicator,
    isBotHandled,
    config,
    label,
    indicatorClass,
  };
}
