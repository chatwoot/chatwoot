<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { maxValue, minLength, minValue, required } from '@vuelidate/validators';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const isCaptainV2Enabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
);

const initialState = {
  handoffMessage: '',
  resolutionMessage: '',
  instructions: '',
  resolveInactiveConversations: true,
  inactivityThresholdMinutes: 60,
};

const state = reactive({ ...initialState });
const isInactivityResolutionSettingsExpanded = ref(false);

const inactivityDurationGroups = computed(() => {
  const minuteOptions = Array.from({ length: 11 }, (_, index) => {
    const minutes = (index + 1) * 5;
    return {
      value: minutes,
      label: t(
        'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES',
        { count: minutes }
      ),
    };
  });

  const hourOptions = Array.from({ length: 24 }, (_, index) => {
    const hours = index + 1;
    return {
      value: hours * 60,
      label:
        hours === 1
          ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_ONE_HOUR')
          : t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS', {
              count: hours,
            }),
    };
  });

  hourOptions.splice(1, 0, {
    value: 90,
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_NINETY_MINUTES'
    ),
  });

  return [
    {
      label: t(
        'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_GROUP_MINUTES'
      ),
      options: minuteOptions,
    },
    {
      label: t(
        'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_GROUP_HOURS'
      ),
      options: hourOptions,
    },
  ];
});

const validationRules = {
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
  instructions: { minLength: minLength(1) },
  inactivityThresholdMinutes: {
    required,
    minValue: minValue(5),
    maxValue: maxValue(24 * 60),
  },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  handoffMessage: getErrorMessage('handoffMessage'),
  resolutionMessage: getErrorMessage('resolutionMessage'),
  instructions: getErrorMessage('instructions'),
  inactivityThresholdMinutes: getErrorMessage('inactivityThresholdMinutes'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.handoffMessage = config.handoff_message;
  state.resolutionMessage = config.resolution_message;
  state.instructions = config.instructions;
  state.resolveInactiveConversations = config.auto_resolve_enabled ?? true;
  state.inactivityThresholdMinutes = config.auto_resolve_after ?? 60;
};

const handleSystemMessagesUpdate = async () => {
  const validations = [
    v$.value.handoffMessage.$validate(),
    v$.value.resolutionMessage.$validate(),
  ];

  if (isCaptainV2Enabled.value) {
    validations.push(v$.value.inactivityThresholdMinutes.$validate());
  } else {
    validations.push(v$.value.instructions.$validate());
  }

  const result = await Promise.all(validations).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      handoff_message: state.handoffMessage,
      resolution_message: state.resolutionMessage,
    },
  };

  if (isCaptainV2Enabled.value) {
    payload.config.auto_resolve_enabled = state.resolveInactiveConversations;
    payload.config.auto_resolve_after = state.inactivityThresholdMinutes;
  } else {
    payload.config.instructions = state.instructions;
  }

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <div
      v-if="isCaptainV2Enabled"
      class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
    >
      <button
        type="button"
        class="flex w-full items-center justify-between gap-4 p-4 text-left"
        :aria-expanded="isInactivityResolutionSettingsExpanded"
        @click="
          isInactivityResolutionSettingsExpanded =
            !isInactivityResolutionSettingsExpanded
        "
      >
        <div class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TITLE') }}
          </h4>
          <p class="text-sm text-n-slate-11">
            {{ t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DESCRIPTION') }}
          </p>
        </div>
        <div class="flex shrink-0 items-center gap-3">
          <span class="text-xs font-medium text-n-slate-11">
            {{
              state.resolveInactiveConversations
                ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.ON')
                : t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.OFF')
            }}
          </span>
          <span
            class="i-lucide-chevron-down size-4 text-n-slate-11 transition-transform"
            :class="{ 'rotate-180': isInactivityResolutionSettingsExpanded }"
          />
        </div>
      </button>

      <div
        v-if="isInactivityResolutionSettingsExpanded"
        class="flex flex-col gap-4 border-t border-n-weak p-4"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex flex-col gap-1">
            <p class="text-sm font-medium text-n-slate-12">
              {{
                t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TOGGLE_LABEL')
              }}
            </p>
            <p class="text-sm text-n-slate-11">
              {{
                t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TOGGLE_HELP')
              }}
            </p>
          </div>
          <Switch v-model="state.resolveInactiveConversations" class="mt-1" />
        </div>

        <div
          v-if="state.resolveInactiveConversations"
          class="flex flex-col gap-2"
        >
          <label class="text-sm font-medium text-n-slate-12">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_LABEL')
            }}
          </label>
          <Select
            v-model="state.inactivityThresholdMinutes"
            :groups="inactivityDurationGroups"
            :error="formErrors.inactivityThresholdMinutes"
            class="!w-full [&>select]:w-full"
          />
          <p
            class="text-xs"
            :class="
              formErrors.inactivityThresholdMinutes
                ? 'text-n-ruby-9'
                : 'text-n-slate-11'
            "
          >
            {{
              formErrors.inactivityThresholdMinutes ||
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HELP')
            }}
          </p>
        </div>
      </div>
    </div>

    <Editor
      v-model="state.handoffMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.PLACEHOLDER')"
      :message="formErrors.handoffMessage"
      :message-type="formErrors.handoffMessage ? 'error' : 'info'"
      class="z-0"
    />

    <Editor
      v-model="state.resolutionMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')"
      :message="formErrors.resolutionMessage"
      :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
      class="z-0"
    />

    <Editor
      v-if="!isCaptainV2Enabled"
      v-model="state.instructions"
      :label="t('CAPTAIN.ASSISTANTS.FORM.INSTRUCTIONS.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.INSTRUCTIONS.PLACEHOLDER')"
      :message="formErrors.instructions"
      :max-length="20000"
      :message-type="formErrors.instructions ? 'error' : 'info'"
      class="z-0"
    />

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleSystemMessagesUpdate"
      />
    </div>
  </div>
</template>
