import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const createClientId = () =>
  globalThis.crypto?.randomUUID?.() ||
  `playground-${Date.now()}-${Math.random().toString(36).slice(2)}`;

const ruleEntries = (type, rules) =>
  (rules || []).map((content, index) => ({
    key: `${type}-saved-${index}`,
    content,
    included: true,
  }));

export function usePlaygroundSession({ assistantId }) {
  const { t } = useI18n();
  const store = useStore();
  const { isAdmin } = useAdmin();

  const isInitializing = ref(false);
  const loadError = ref('');
  const savedScenarios = ref([]);
  const includedScenarioIds = ref([]);
  const temporaryScenarios = ref([]);
  const savedGuidelines = ref([]);
  const temporaryGuidelines = ref([]);
  const savedGuardrails = ref([]);
  const temporaryGuardrails = ref([]);
  const knowledgeText = ref('');
  const isKnowledgeIncluded = ref(true);
  const knowledgeStats = ref({ documents: 0, faqs: 0 });
  let initializationSequence = 0;

  const scenarioIsValid = scenario =>
    Boolean(
      scenario.title.trim() &&
        scenario.description.trim() &&
        scenario.instruction.trim()
    );

  const includedScenarios = computed(() =>
    savedScenarios.value.filter(scenario =>
      includedScenarioIds.value.includes(scenario.id)
    )
  );

  const includedTemporaryScenarios = computed(() =>
    temporaryScenarios.value.filter(scenario => scenario.included)
  );
  const isValid = computed(() =>
    includedTemporaryScenarios.value.every(scenarioIsValid)
  );

  const includedRules = (saved, temporary) => [
    ...saved.value.filter(rule => rule.included).map(rule => rule.content),
    ...temporary.value
      .filter(rule => rule.included && rule.content.trim())
      .map(rule => rule.content.trim()),
  ];

  const playgroundConfig = computed(() => ({
    scenario_ids: includedScenarios.value.map(scenario => scenario.id),
    temporary_scenarios: includedTemporaryScenarios.value.map(
      ({ clientId, title, description, instruction }) => ({
        client_id: clientId,
        title: title.trim(),
        description: description.trim(),
        instruction: instruction.trim(),
      })
    ),
    response_guidelines: includedRules(savedGuidelines, temporaryGuidelines),
    guardrails: includedRules(savedGuardrails, temporaryGuardrails),
    knowledge_text: isKnowledgeIncluded.value ? knowledgeText.value : '',
  }));

  const configurationSummary = () => ({
    scenarioCount:
      includedScenarios.value.length + includedTemporaryScenarios.value.length,
    guidelineCount: playgroundConfig.value.response_guidelines.length,
    guardrailCount: playgroundConfig.value.guardrails.length,
    hasKnowledge: Boolean(
      isKnowledgeIncluded.value && knowledgeText.value.trim()
    ),
  });

  const toggleScenario = id => {
    includedScenarioIds.value = includedScenarioIds.value.includes(id)
      ? includedScenarioIds.value.filter(scenarioId => scenarioId !== id)
      : [...includedScenarioIds.value, id];
  };

  const addTemporaryScenario = () => {
    temporaryScenarios.value.push({
      clientId: createClientId(),
      title: '',
      description: '',
      instruction: '',
      included: true,
      isSaving: false,
    });
  };

  const removeTemporaryScenario = clientId => {
    temporaryScenarios.value = temporaryScenarios.value.filter(
      scenario => scenario.clientId !== clientId
    );
  };

  const saveTemporaryScenario = async scenario => {
    if (!scenarioIsValid(scenario) || scenario.isSaving) return;
    const targetAssistantId = assistantId.value;
    scenario.isSaving = true;
    try {
      const savedScenario = await store.dispatch('captainScenarios/create', {
        assistantId: targetAssistantId,
        title: scenario.title.trim(),
        description: scenario.description.trim(),
        instruction: scenario.instruction.trim(),
        enabled: true,
      });
      if (assistantId.value !== targetAssistantId) return;

      savedScenarios.value = [savedScenario, ...savedScenarios.value];
      includedScenarioIds.value = [
        ...includedScenarioIds.value,
        savedScenario.id,
      ];
      removeTemporaryScenario(scenario.clientId);
      useAlert(t('CAPTAIN.PLAYGROUND.SETUP.SAVE_SCENARIO_SUCCESS'));
    } catch (error) {
      if (assistantId.value !== targetAssistantId) return;

      useAlert(
        error?.message || t('CAPTAIN.PLAYGROUND.SETUP.SAVE_SCENARIO_ERROR')
      );
    } finally {
      scenario.isSaving = false;
    }
  };

  const addTemporaryRule = type => {
    const target =
      type === 'guideline' ? temporaryGuidelines : temporaryGuardrails;
    target.value.push({
      clientId: createClientId(),
      content: '',
      included: true,
      isSaving: false,
    });
  };

  const removeTemporaryRule = (type, clientId) => {
    const target =
      type === 'guideline' ? temporaryGuidelines : temporaryGuardrails;
    target.value = target.value.filter(rule => rule.clientId !== clientId);
  };

  const replaceSavedRules = (type, rules, newlySavedContent) => {
    const target = type === 'guideline' ? savedGuidelines : savedGuardrails;
    const includedContent = new Set(
      target.value.filter(rule => rule.included).map(rule => rule.content)
    );
    target.value = ruleEntries(type, rules).map(rule => ({
      ...rule,
      included:
        rule.content === newlySavedContent || includedContent.has(rule.content),
    }));
  };

  const saveTemporaryRule = async (type, rule) => {
    const content = rule.content.trim();
    if (!content || rule.isSaving) return;
    const targetAssistantId = assistantId.value;
    rule.isSaving = true;
    try {
      const latestAssistant = await store.dispatch(
        'captainAssistants/show',
        targetAssistantId
      );
      const field = type === 'guideline' ? 'response_guidelines' : 'guardrails';
      const latestRules = latestAssistant?.[field] || [];

      if (latestRules.includes(content)) {
        if (assistantId.value !== targetAssistantId) return;

        replaceSavedRules(type, latestRules, content);
        removeTemporaryRule(type, rule.clientId);
        useAlert(t('CAPTAIN.PLAYGROUND.SETUP.RULE_ALREADY_SAVED'));
        return;
      }

      const updatedRules = [...latestRules, content];
      await store.dispatch('captainAssistants/update', {
        id: targetAssistantId,
        assistant: { [field]: updatedRules },
      });
      if (assistantId.value !== targetAssistantId) return;

      replaceSavedRules(type, updatedRules, content);
      removeTemporaryRule(type, rule.clientId);
      useAlert(t('CAPTAIN.PLAYGROUND.SETUP.SAVE_RULE_SUCCESS'));
    } catch (error) {
      if (assistantId.value !== targetAssistantId) return;

      useAlert(error?.message || t('CAPTAIN.PLAYGROUND.SETUP.SAVE_RULE_ERROR'));
    } finally {
      rule.isSaving = false;
    }
  };

  const initialize = async () => {
    initializationSequence += 1;
    const sequence = initializationSequence;
    const targetAssistantId = assistantId.value;
    const isCurrentInitialization = () =>
      sequence === initializationSequence &&
      targetAssistantId === assistantId.value;

    isInitializing.value = true;
    loadError.value = '';
    try {
      const [assistant, scenarios, , faqStatsResponse] = await Promise.all([
        store.dispatch('captainAssistants/show', targetAssistantId),
        store.dispatch('captainScenarios/get', {
          assistantId: targetAssistantId,
        }),
        store.dispatch('captainTools/getTools'),
        CaptainAssistant.getFaqStats({ assistantId: targetAssistantId }).catch(
          () => null
        ),
      ]);
      if (!isCurrentInitialization()) return;

      savedScenarios.value = scenarios || [];
      includedScenarioIds.value = savedScenarios.value
        .filter(scenario => scenario.enabled)
        .map(scenario => scenario.id);
      savedGuidelines.value = ruleEntries(
        'guideline',
        assistant?.response_guidelines
      );
      savedGuardrails.value = ruleEntries('guardrail', assistant?.guardrails);
      knowledgeStats.value = {
        documents: Number(faqStatsResponse?.data?.documents) || 0,
        faqs: Number(faqStatsResponse?.data?.faqs) || 0,
      };
    } catch (error) {
      if (!isCurrentInitialization()) return;

      loadError.value =
        error?.message || t('CAPTAIN.PLAYGROUND.SETUP.LOAD_ERROR');
    } finally {
      if (isCurrentInitialization()) isInitializing.value = false;
    }
  };

  const clearTemporaryState = () => {
    temporaryScenarios.value = [];
    temporaryGuidelines.value = [];
    temporaryGuardrails.value = [];
    knowledgeText.value = '';
    isKnowledgeIncluded.value = true;
  };

  const reset = async () => {
    clearTemporaryState();
    await initialize();
  };

  const setKnowledgeText = value => {
    knowledgeText.value = value;
  };

  const setKnowledgeIncluded = value => {
    isKnowledgeIncluded.value = value;
  };

  const incrementFaqCount = () => {
    knowledgeStats.value = {
      ...knowledgeStats.value,
      faqs: knowledgeStats.value.faqs + 1,
    };
  };

  return {
    isAdmin,
    isInitializing,
    loadError,
    savedScenarios,
    includedScenarioIds,
    temporaryScenarios,
    savedGuidelines,
    temporaryGuidelines,
    savedGuardrails,
    temporaryGuardrails,
    knowledgeText,
    isKnowledgeIncluded,
    knowledgeStats,
    playgroundConfig,
    isValid,
    configurationSummary,
    initialize,
    reset,
    toggleScenario,
    addTemporaryScenario,
    removeTemporaryScenario,
    scenarioIsValid,
    saveTemporaryScenario,
    addTemporaryRule,
    removeTemporaryRule,
    saveTemporaryRule,
    setKnowledgeText,
    setKnowledgeIncluded,
    incrementFaqCount,
  };
}
