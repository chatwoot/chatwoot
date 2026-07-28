import { computed, unref } from 'vue';

export const MESSAGE_SOURCE_ICONS = {
  automation: 'i-lucide-repeat',
  macro: 'i-lucide-toy-brick',
  flow: 'i-lucide-git-branch',
};

export const MESSAGE_SOURCE_I18N = {
  automation: 'MESSAGE_SOURCE.AUTOMATION',
  macro: 'MESSAGE_SOURCE.MACRO',
  flow: 'MESSAGE_SOURCE.FLOW',
};

function readLegacySource(attrs) {
  const automationId = attrs.automationRuleId ?? attrs.automation_rule_id;
  if (automationId) {
    return {
      type: 'automation',
      id: automationId,
      name: attrs.automationRuleName ?? attrs.automation_rule_name,
    };
  }

  const macroId = attrs.macroId ?? attrs.macro_id;
  if (macroId) {
    return {
      type: 'macro',
      id: macroId,
      name: attrs.macroName ?? attrs.macro_name,
    };
  }

  const flowRunId = attrs.flowRunId ?? attrs.flow_run_id;
  const flowId = attrs.flowId ?? attrs.flow_id;
  if (flowRunId || flowId) {
    return {
      type: 'flow',
      id: flowId ?? flowRunId,
      name: attrs.flowName ?? attrs.flow_name,
    };
  }

  return null;
}

export function useMessageSource(contentAttributes) {
  const source = computed(() => {
    const attrs = unref(contentAttributes) || {};
    const explicit = attrs.messageSource ?? attrs.message_source;
    if (explicit?.type) {
      return {
        type: explicit.type,
        id: explicit.id,
        name: explicit.name,
      };
    }

    return readLegacySource(attrs);
  });

  const icon = computed(() => MESSAGE_SOURCE_ICONS[source.value?.type] || null);

  const i18nKey = computed(
    () => MESSAGE_SOURCE_I18N[source.value?.type] || null
  );

  const hasSource = computed(() => Boolean(source.value?.type));

  return { source, icon, i18nKey, hasSource };
}
