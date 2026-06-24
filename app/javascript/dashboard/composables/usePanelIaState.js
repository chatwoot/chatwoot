import { computed, unref } from 'vue';
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

  return {
    state,
    showIndicator,
    isBotHandled,
    config,
    label,
    indicatorClass,
  };
}
