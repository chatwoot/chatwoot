import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useMacroExecution } from 'dashboard/composables/useMacroExecution';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';

const ICON = 'i-lucide-toy-brick';
const SCOPES = ['conversation'];

export function useMacroCommands() {
  const { t } = useI18n();
  const store = useStore();
  const route = useRoute();

  const { orderedMacros } = useOrderedMacros();
  const { execute, submitPendingAttributes, dismissPendingAttributes } =
    useMacroExecution();
  const { isFeatureFlagEnabled } = usePolicy();

  const currentChat = useMapGetter('getSelectedChat');
  const pendingAttributes = ref(null);

  const isMacrosAvailable = computed(
    () =>
      isFeatureFlagEnabled(FEATURE_FLAGS.MACROS) &&
      (isAConversationRoute(route.name) || isAInboxViewRoute(route.name))
  );

  watch(
    isMacrosAvailable,
    isActive => {
      if (isActive && !orderedMacros.value.length) store.dispatch('macros/get');
    },
    { immediate: true }
  );

  const macroCommands = computed(() => {
    if (!isMacrosAvailable.value || !orderedMacros.value.length) return [];

    return [
      {
        id: 'execute_a_macro',
        title: t('COMMAND_BAR.COMMANDS.EXECUTE_A_MACRO'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON,
        scopes: SCOPES,
        page: true,
      },
      ...orderedMacros.value.map(macro => ({
        id: `macro-${macro.id}`,
        title: macro.name,
        parent: 'execute_a_macro',
        section: t('COMMAND_BAR.SECTIONS.EXECUTE_MACRO'),
        icon: ICON,
        scopes: SCOPES,
        run: () => {
          pendingAttributes.value = execute(macro, currentChat.value.id);
        },
      })),
    ];
  });

  return {
    macroCommands,
    pendingAttributes,
    submitPendingAttributes,
    dismissPendingAttributes,
  };
}
