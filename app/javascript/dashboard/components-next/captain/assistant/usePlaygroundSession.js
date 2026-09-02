import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const createClientId = () =>
  globalThis.crypto?.randomUUID?.() ||
  `playground-${Date.now()}-${Math.random().toString(36).slice(2)}`;

const createMarkdownFilename = () =>
  `playground-knowledge-${new Date().toISOString().replace(/[:.]/g, '-')}.md`;

const normalizedRuleContents = rules => [
  ...new Set((rules || []).map(content => content.trim()).filter(Boolean)),
];

const ruleEntries = (type, rules) =>
  normalizedRuleContents(rules).map((content, index) => ({
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
  const savingKnowledgeAssistantIds = ref(new Set());
  const savingRuleTypes = ref(new Set());
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

  const includedRules = (saved, temporary) =>
    normalizedRuleContents(
      [...saved.value, ...temporary.value]
        .filter(rule => rule.included)
        .map(rule => rule.content)
    );

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

  const addTemporaryScenario = title => {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return;

    temporaryScenarios.value.push({
      clientId: createClientId(),
      title: normalizedTitle,
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

      savedScenarios.value = [
        savedScenario,
        ...savedScenarios.value.filter(item => item.id !== savedScenario.id),
      ];
      includedScenarioIds.value = [
        ...new Set([...includedScenarioIds.value, savedScenario.id]),
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

  const addTemporaryRule = (type, content) => {
    const normalizedContent = content?.trim();
    if (!normalizedContent) return;

    const target =
      type === 'guideline' ? temporaryGuidelines : temporaryGuardrails;
    target.value.push({
      clientId: createClientId(),
      content: normalizedContent,
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
      target.value
        .filter(rule => rule.included)
        .map(rule => rule.content.trim())
    );
    target.value = ruleEntries(type, rules).map(rule => ({
      ...rule,
      included:
        rule.content === newlySavedContent.trim() ||
        includedContent.has(rule.content),
    }));
  };

  const ruleSaveKey = (type, targetAssistantId = assistantId.value) =>
    `${targetAssistantId}:${type}`;
  const isRuleTypeSaving = type => savingRuleTypes.value.has(ruleSaveKey(type));

  const setRuleTypeSaving = (type, targetAssistantId, isSaving) => {
    const nextSavingRuleTypes = new Set(savingRuleTypes.value);
    const key = ruleSaveKey(type, targetAssistantId);
    if (isSaving) {
      nextSavingRuleTypes.add(key);
    } else {
      nextSavingRuleTypes.delete(key);
    }
    savingRuleTypes.value = nextSavingRuleTypes;
  };

  const saveTemporaryRule = async (type, rule) => {
    const content = rule.content.trim();
    if (!content || rule.isSaving || isRuleTypeSaving(type)) return;
    const targetAssistantId = assistantId.value;
    setRuleTypeSaving(type, targetAssistantId, true);
    rule.isSaving = true;
    try {
      const latestAssistant = await store.dispatch(
        'captainAssistants/show',
        targetAssistantId
      );
      const field = type === 'guideline' ? 'response_guidelines' : 'guardrails';
      const latestRules = normalizedRuleContents(latestAssistant?.[field]);

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
      setRuleTypeSaving(type, targetAssistantId, false);
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

      savedScenarios.value = [...(scenarios || [])];
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

  const isSavingKnowledge = computed(() =>
    savingKnowledgeAssistantIds.value.has(assistantId.value)
  );

  const setKnowledgeSaving = (targetAssistantId, isSaving) => {
    const nextSavingAssistantIds = new Set(savingKnowledgeAssistantIds.value);
    if (isSaving) {
      nextSavingAssistantIds.add(targetAssistantId);
    } else {
      nextSavingAssistantIds.delete(targetAssistantId);
    }
    savingKnowledgeAssistantIds.value = nextSavingAssistantIds;
  };

  const saveKnowledgeAsDocument = async () => {
    const content = knowledgeText.value.trim();
    if (!content || isSavingKnowledge.value) return;

    const targetAssistantId = assistantId.value;
    const filename = createMarkdownFilename();

    setKnowledgeSaving(targetAssistantId, true);
    try {
      await store.dispatch('captainDocuments/create', {
        document: {
          assistant_id: targetAssistantId,
          name: filename,
          markdown_content: content,
        },
      });
      if (assistantId.value !== targetAssistantId) return;

      knowledgeStats.value = {
        ...knowledgeStats.value,
        documents: knowledgeStats.value.documents + 1,
      };
      useAlert(t('CAPTAIN.PLAYGROUND.SETUP.SAVE_KNOWLEDGE_SUCCESS'));
    } catch (error) {
      if (assistantId.value !== targetAssistantId) return;

      useAlert(
        error?.message || t('CAPTAIN.PLAYGROUND.SETUP.SAVE_KNOWLEDGE_ERROR')
      );
    } finally {
      setKnowledgeSaving(targetAssistantId, false);
    }
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
    isSavingKnowledge,
    isRuleTypeSaving,
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
    saveKnowledgeAsDocument,
  };
}
