import { computed, unref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  isBotHandledConversation,
  isHumanAssigneeMeta,
} from 'dashboard/helper/assigneeHelper';

const STATE_CONFIG = {
  activo: {
    indicatorClass: 'bg-n-teal-9/10',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_ACTIVE',
  },
  esperando: {
    indicatorClass: 'bg-n-amber-9/10',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_WAITING',
  },
  solicita_ayuda: {
    indicatorClass: 'bg-n-ruby-9/10',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_HELP',
    pulseIndicator: true,
  },
  cerrado_inactividad: {
    indicatorClass: 'bg-n-slate-9/10',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_INACTIVITY_CLOSED',
  },
};

export function usePanelIaState(chatRef) {
  const { t } = useI18n();

  const isHumanAssigned = computed(() =>
    isHumanAssigneeMeta(unref(chatRef)?.meta)
  );

  const isBotHandled = computed(() => isBotHandledConversation(unref(chatRef)));

  const hasFlowState = computed(() => {
    const chat = unref(chatRef);
    return Boolean(
      chat?.flow_run ||
        chat?.custom_attributes?.panel_ia_estado ||
        chat?.custom_attributes?.panel_ia_estado_label
    );
  });

  const state = computed(() => {
    if (isHumanAssigned.value) return '';

    const chat = unref(chatRef);
    const estado = chat?.custom_attributes?.panel_ia_estado;
    if (estado) return estado;
    if (chat?.flow_run?.state === 'waiting') return 'esperando';
    if (chat?.flow_run?.state === 'running') return 'activo';
    if (['handed_off', 'failed'].includes(chat?.flow_run?.state)) {
      return 'solicita_ayuda';
    }
    if (chat?.status === 'resolved' && isBotHandled.value) {
      return 'cerrado_inactividad';
    }
    return isBotHandled.value ? 'activo' : '';
  });

  const showIndicator = computed(
    () =>
      !isHumanAssigned.value &&
      (isBotHandled.value || hasFlowState.value) &&
      Boolean(STATE_CONFIG[state.value])
  );

  const config = computed(() => STATE_CONFIG[state.value] || null);

  const label = computed(() => {
    const chat = unref(chatRef);
    const customLabel = chat?.custom_attributes?.panel_ia_estado_label;
    if (customLabel) return customLabel;
    if (!config.value) return '';
    return t(config.value.labelKey);
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
