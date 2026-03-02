import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useLlmChat } from 'dashboard/composables/useLlmChat';
import {
  WIZARD_SYSTEM_PROMPT,
  WIZARD_STEPS,
  extractWizardResult,
  estimateWizardStep,
} from '../helpers/wizardPrompt';

/**
 * Composable for the AI agent conversational setup wizard.
 *
 * Wraps useLlmChat with wizard-specific logic:
 * - Tracks conversation step progress
 * - Detects when the LLM outputs the final JSON config
 * - Creates the agent with the generated config
 */
export function useSetupWizard() {
  const { t } = useI18n();
  const store = useStore();

  const wizardResult = ref(null);
  const isCreatingAgent = ref(false);
  const currentStepIndex = ref(0);

  const {
    messages,
    isStreaming,
    error,
    sendMessage,
    connect,
    disconnect,
    clearMessages,
  } = useLlmChat({
    model: 'litellm/gpt-4.1-mini',
    systemPrompt: WIZARD_SYSTEM_PROMPT,
    temperature: 0.7,
    feature: 'agent_wizard',
  });

  const isComplete = computed(() => !!wizardResult.value);

  const currentStep = computed(() => WIZARD_STEPS[currentStepIndex.value]);

  const progressPercent = computed(
    () => ((currentStepIndex.value + 1) / WIZARD_STEPS.length) * 100
  );

  const stepLabels = computed(() =>
    WIZARD_STEPS.map(step => {
      const key = step.toUpperCase();
      return t(`AI_AGENTS.WIZARD.STEPS.${key}`);
    })
  );

  /**
   * Send a user message and check assistant response for completion JSON.
   */
  const sendWizardMessage = async content => {
    await sendMessage(content);

    // After response, update step estimate
    const userMessageCount = messages.value.filter(
      m => m.role === 'user'
    ).length;
    currentStepIndex.value = estimateWizardStep(userMessageCount * 2);

    // Check the latest assistant message for completion
    const lastAssistant = [...messages.value]
      .reverse()
      .find(m => m.role === 'assistant' && !m.isStreaming);

    if (lastAssistant) {
      const result = extractWizardResult(lastAssistant.content);
      if (result) {
        wizardResult.value = result;
        currentStepIndex.value = WIZARD_STEPS.length - 1;
      }
    }
  };

  /**
   * Create the agent from the wizard-generated config.
   */
  const createAgentFromWizard = async () => {
    if (!wizardResult.value) return null;

    isCreatingAgent.value = true;
    try {
      const result = wizardResult.value;
      const agentData = {
        name: result.name || t('AI_AGENTS.FORM.NAME.PLACEHOLDER'),
        description: result.description || '',
        agent_type: 'rag',
        config: {
          prompt_sections: result.prompt_sections || {},
        },
      };

      const agent = await store.dispatch('aiAgents/create', agentData);
      useAlert(t('AI_AGENTS.CREATE.SUCCESS_MESSAGE'));
      return agent;
    } catch (err) {
      useAlert(err?.message || t('AI_AGENTS.CREATE.ERROR_MESSAGE'));
      return null;
    } finally {
      isCreatingAgent.value = false;
    }
  };

  /**
   * Reset the wizard to start over.
   */
  const resetWizard = () => {
    wizardResult.value = null;
    currentStepIndex.value = 0;
    clearMessages();
  };

  /**
   * Start the wizard — connect cable and send initial greeting trigger.
   */
  const startWizard = () => {
    connect();
  };

  return {
    // State
    messages,
    isStreaming,
    error,
    wizardResult,
    isCreatingAgent,
    isComplete,
    currentStep,
    currentStepIndex,
    progressPercent,
    stepLabels,

    // Actions
    sendWizardMessage,
    createAgentFromWizard,
    resetWizard,
    startWizard,
    connect,
    disconnect,
  };
}
