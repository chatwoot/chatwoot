<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { maxValue, minLength, minValue, required } from '@vuelidate/validators';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Select from 'dashboard/components-next/select/Select.vue';

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
  autoResolveMode: 'evaluated',
  inactivityThresholdMinutes: 60,
};

const state = reactive({ ...initialState });
const isInactivityResolutionSettingsExpanded = ref(false);

const autoResolveOptions = computed(() => [
  {
    value: 'disabled',
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.DISABLED.LABEL'
    ),
    description: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.DISABLED.DESCRIPTION'
    ),
  },
  {
    value: 'legacy',
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.LEGACY.LABEL'
    ),
    description: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.LEGACY.DESCRIPTION'
    ),
  },
  {
    value: 'evaluated',
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.EVALUATED.LABEL'
    ),
    description: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.EVALUATED.DESCRIPTION'
    ),
  },
]);

const selectedAutoResolveModeLabel = computed(() => {
  return autoResolveOptions.value.find(
    option => option.value === state.autoResolveMode
  )?.label;
});

const inactivityThresholdLabel = computed(() => {
  const hours = Math.floor(state.inactivityThresholdMinutes / 60);
  const minutes = state.inactivityThresholdMinutes % 60;

  return [
    hours
      ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS', {
          count: hours,
        })
      : '',
    minutes
      ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES', {
          count: minutes,
        })
      : '',
  ]
    .filter(Boolean)
    .join(' ');
});

const selectedInactivityResolutionSummary = computed(() => {
  if (state.autoResolveMode === 'disabled') {
    return t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.CURRENT_MODE', {
      mode: selectedAutoResolveModeLabel.value,
    });
  }

  return t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.CURRENT_MODE_AFTER', {
    mode: selectedAutoResolveModeLabel.value,
    duration: inactivityThresholdLabel.value,
  });
});

const shouldShowInactivityDuration = computed(
  () => state.autoResolveMode !== 'disabled'
);

const inactivityHourOptions = Array.from({ length: 25 }, (_, hours) => ({
  value: hours,
  label: String(hours),
}));

const inactivityThresholdHours = computed({
  get: () => Math.floor(state.inactivityThresholdMinutes / 60),
  set: hours => {
    const remainingMinutes = state.inactivityThresholdMinutes % 60;
    const requestedMinutes = Number(hours) * 60 + remainingMinutes;
    state.inactivityThresholdMinutes = Math.min(
      Math.max(requestedMinutes, 5),
      24 * 60
    );
  },
});

const inactivityThresholdRemainingMinutes = computed({
  get: () => state.inactivityThresholdMinutes % 60,
  set: minutes => {
    const completeHours = Math.floor(state.inactivityThresholdMinutes / 60);
    const requestedMinutes = completeHours * 60 + Number(minutes);
    state.inactivityThresholdMinutes = Math.min(
      Math.max(requestedMinutes, 5),
      24 * 60
    );
  },
});

const inactivityMinuteOptions = computed(() => {
  return Array.from({ length: 12 }, (_, index) => {
    const minutes = index * 5;
    const hours = inactivityThresholdHours.value;

    return {
      value: minutes,
      label: String(minutes).padStart(2, '0'),
      disabled:
        (hours === 0 && minutes === 0) || (hours === 24 && minutes !== 0),
    };
  });
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
  state.autoResolveMode = config.auto_resolve_mode ?? 'evaluated';
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
    payload.config.auto_resolve_mode = state.autoResolveMode;
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
          <p
            v-if="!isInactivityResolutionSettingsExpanded"
            class="text-xs font-medium text-n-slate-12"
          >
            {{ selectedInactivityResolutionSummary }}
          </p>
        </div>
        <div class="flex shrink-0 items-center">
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
        <div class="flex flex-col gap-3">
          <RadioCard
            v-for="option in autoResolveOptions"
            :id="`auto-resolve-${option.value}`"
            :key="option.value"
            :label="option.label"
            :description="option.description"
            :is-active="state.autoResolveMode === option.value"
            @select="state.autoResolveMode = option.value"
          />
        </div>

        <div v-if="shouldShowInactivityDuration" class="flex flex-col gap-2">
          <p class="text-sm font-medium text-n-slate-12">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_LABEL')
            }}
          </p>
          <div class="grid grid-cols-2 gap-3">
            <label class="flex flex-col gap-1.5 text-xs text-n-slate-11">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS_LABEL'
                )
              }}
              <Select
                v-model="inactivityThresholdHours"
                :options="inactivityHourOptions"
                :error="formErrors.inactivityThresholdMinutes"
                class="!w-full [&>select]:w-full"
              />
            </label>
            <label class="flex flex-col gap-1.5 text-xs text-n-slate-11">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES_LABEL'
                )
              }}
              <Select
                v-model="inactivityThresholdRemainingMinutes"
                :options="inactivityMinuteOptions"
                :error="formErrors.inactivityThresholdMinutes"
                class="!w-full [&>select]:w-full"
              />
            </label>
          </div>
          <p
            v-if="formErrors.inactivityThresholdMinutes"
            class="text-xs text-n-ruby-9"
          >
            {{ formErrors.inactivityThresholdMinutes }}
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
