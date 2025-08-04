<script setup>
import { computed, shallowRef, ref, onMounted, watchEffect } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import AIBackendAPI from 'v3/api/ai_backend';
import Button from '../../../../shared/components/Button.vue';
import OnboardingViewAddAgent from './OnboardingView.AddAgent.vue';
import OnboardingViewAddChannel from './OnboardingView.AddChannel.vue';
import OnboardingViewAddAIAgent from './OnboardingView.AddAIAgent.vue';
import StepCircleFlow from '../../../../shared/components/StepCircleFlow.vue';
import { useAlert } from 'dashboard/composables';

const getters = useStoreGetters();
const store = useStore();
const { currentAccount } = useAccount();

const { t } = useI18n();
const globalConfig = computed(() => getters['globalConfig/get'].value);
const currentUser = computed(() => getters.getCurrentUser.value);
const isLoading = ref(true);

const agents = useMapGetter('agents/getAgents');
const inboxes = useMapGetter('inboxes/getInboxes');
const bots = useMapGetter('agentBots/getBots');

const currentStep = ref(1);
const stepCompletionStatus = ref({});
const stepOrder = shallowRef({
  addAgentsStep: 1,
  addChannelStep: 2,
  addAIAgentStep: 3,
});
const ONBOARDING_STEP_KEY = 'chatscommerce_onboarding_current_step';

const onboardingSteps = shallowRef({
  [stepOrder.value.addAgentsStep]: {
    title: t('ONBOARDING.TEAM_MEMBERS.TITLE'),
    description: t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION'),
    component: OnboardingViewAddAgent,
    props: {
      stepNumber: stepOrder.value.addAgentsStep,
    },
    icon: {
      src: 'i-lucide-users',
      class: 'size-8 bg-white',
    },
    completeCondition: computed(() => agents?.value?.length >= 1),
  },
  [stepOrder.value.addChannelStep]: {
    title: t('ONBOARDING.ADD_CHANNEL.TITLE'),
    description: t('ONBOARDING.ADD_CHANNEL.DESCRIPTION'),
    component: OnboardingViewAddChannel,
    props: {
      stepNumber: stepOrder.value.addChannelStep,
    },
    icon: {
      src: 'i-lucide-messages-square',
      class: 'size-8 bg-white',
    },
    completeCondition: computed(() => {
      if (inboxes.value?.length > 0) {
        return inboxes.value[0].has_members;
      }
      return false;
    }),
  },
  [stepOrder.value.addAIAgentStep]: {
    title: t('ONBOARDING.ADD_AI_AGENT.TITLE'),
    description: t('ONBOARDING.ADD_AI_AGENT.DESCRIPTION'),
    component: OnboardingViewAddAIAgent,
    props: {
      stepNumber: stepOrder.value.addAIAgentStep,
    },
    icon: {
      src: 'i-lucide-bot-message-square',
      class: 'size-8 bg-white',
    },
    completeCondition: computed(() => bots?.value?.length > 0),
  },
});

const greetingMessage = computed(() => {
  const hours = new Date().getHours();
  let translationKey;
  if (hours < 12) {
    translationKey = 'ONBOARDING.GREETING_MORNING';
  } else if (hours < 18) {
    translationKey = 'ONBOARDING.GREETING_AFTERNOON';
  } else {
    translationKey = 'ONBOARDING.GREETING_EVENING';
  }
  return t(translationKey, {
    name: currentUser.value.name,
    installationName: globalConfig.value.installationName,
  });
});

function loadSavedStep() {
  try {
    const savedStep = localStorage.getItem(ONBOARDING_STEP_KEY);
    if (savedStep !== null) {
      const stepNumber = parseInt(savedStep, 10);
      if (stepNumber >= 1 && stepNumber <= 3) {
        currentStep.value = stepNumber;
      }
    }
  } catch (error) {
    useAlert(t('ONBOARDING.ERROR.STEP_NOT_LOADED'));
    currentStep.value = 1;
  }
}

function saveCurrentStep(step) {
  try {
    localStorage.setItem(ONBOARDING_STEP_KEY, step.toString());
  } catch (error) {
    useAlert(t('ONBOARDING.ERROR.STEP_NOT_SAVED'));
    localStorage.setItem(ONBOARDING_STEP_KEY, '1');
  }
}

async function finishHandler() {
  try {
    const accountId = currentAccount.value?.id;

    const botToken = bots.value?.[0]?.access_token;
    if (botToken) {
      const chatwootConfig = {
        chatwoot: {
          type: 'chatwoot',
          enabled: true,
          bot_api_token: botToken,
          app_api_token: currentUser.value.access_token,
          account_id: String(accountId),
          inbox_id: String(inboxes.value?.[0]?.id),
          tags: {
            developer: 'pending',
            pruebas: 'pending',
            detenido: 'pending',
            uber: 'pending',
            procesar: 'pending',
            soporte: 'pending',
          },
        },
      };

      await AIBackendAPI.updateOrCreateConfiguration(
        'messaging_config',
        chatwootConfig
      );
    }

    await store.dispatch('accounts/update', {
      onboarding_completed: true,
    });

    useAlert(
      t('ONBOARDING.COMPLETED', {
        installationName: globalConfig.value.installationName,
      })
    );

    localStorage.removeItem(ONBOARDING_STEP_KEY);
  } catch (error) {
    useAlert(t('ONBOARDING.ERROR.BOT_CONFIGURATION'));
  }
}

function backHandler() {
  currentStep.value -= 1;
  saveCurrentStep(currentStep.value);
}

function nextHandler() {
  currentStep.value += 1;
  saveCurrentStep(currentStep.value);
}

function handleStepClick(stepNumber) {
  // Early return if step is not accessible
  if (!stepCompletionStatus.value[stepNumber - 1] && stepNumber > 1) {
    useAlert(t('ONBOARDING.ERROR.STEP_NOT_COMPLETED'));
    return;
  }

  currentStep.value = stepNumber;
  saveCurrentStep(currentStep.value);
}

function checkStepCompletion(step) {
  const isComplete = onboardingSteps.value[step].completeCondition.value;
  if (isComplete) {
    stepCompletionStatus.value[step] = true;
  }
}

watchEffect(() => {
  // Populate stepCompletionStatus with current completion state
  checkStepCompletion(stepOrder.value.addAgentsStep);
  checkStepCompletion(stepOrder.value.addChannelStep);
  checkStepCompletion(stepOrder.value.addAIAgentStep);
});

onMounted(async () => {
  loadSavedStep();

  const promises = [];

  if (!agents.value?.length) {
    promises.push(store.dispatch('agents/get'));
  }
  if (!inboxes.value?.length) {
    promises.push(store.dispatch('inboxes/get'));
  }
  if (!bots.value?.length) {
    promises.push(store.dispatch('agentBots/get'));
  }
  await Promise.all(promises);

  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
});
</script>

<template>
  <div>
    <div
      v-if="!isLoading"
      class="flex flex-col min-h-screen max-h-screen lg:max-w-6xl max-w-4xl gap-4 p-8 font-inter overflow-auto"
    >
      <!--Greeting-->
      <section class="w-full mx-auto">
        <p
          class="text-xl font-semibold text-center text-slate-900 dark:text-white font-interDisplay tracking-[0.3px]"
        >
          {{ greetingMessage }}
        </p>
        <p class="text-slate-600 dark:text-slate-400 text-base">
          {{
            $t('ONBOARDING.DESCRIPTION', {
              installationName: globalConfig.installationName,
            })
          }}
        </p>
      </section>

      <section class="flex flex-col my-4 mb-10 h-full gap-4">
        <!--Circle Step Indicator-->
        <StepCircleFlow
          :steps="onboardingSteps"
          :current-step="currentStep"
          :steps-completed="stepCompletionStatus"
          @update:current-step="handleStepClick"
        />

        <!--OnboardingViews-->
        <div class="h-full my-8 w-full mx-auto">
          <component
            :is="onboardingSteps[currentStep].component"
            v-bind="onboardingSteps[currentStep].props"
            :current-step="currentStep"
          />
          <!--Navigation Buttons-->
          <div class="flex mt-10 justify-between">
            <div>
              <Button v-if="currentStep > 1" @click="backHandler">
                {{ $t('ONBOARDING.BUTTON.PREVIOUS') }}
              </Button>
            </div>
            <div>
              <Button
                v-if="currentStep < Object.keys(onboardingSteps).length"
                :disabled="!stepCompletionStatus[currentStep]"
                @click="nextHandler"
              >
                {{ $t('ONBOARDING.BUTTON.NEXT') }}
              </Button>
              <Button
                v-if="
                  currentStep == Object.keys(onboardingSteps).length &&
                  stepCompletionStatus[currentStep]
                "
                @click="finishHandler()"
              >
                {{ $t('ONBOARDING.BUTTON.FINISH') }}
              </Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>
