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
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';

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
  followUpBeforeResolving: false,
  followUpResolveAfterMinutes: 60,
  sendInactivityResolutionMessage: true,
};

const state = reactive({ ...initialState });
const isInactivityResolutionSettingsExpanded = ref(false);

const autoResolveOptions = computed(() => [
  {
    value: 'evaluated',
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.EVALUATED.LABEL'
    ),
    description: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.EVALUATED.DESCRIPTION'
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
    value: 'disabled',
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.DISABLED.LABEL'
    ),
    description: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODES.DISABLED.DESCRIPTION'
    ),
  },
]);

const formatDuration = durationMinutes => {
  const hours = Math.floor(durationMinutes / 60);
  const minutes = durationMinutes % 60;

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
};

const inactivityThresholdLabel = computed(() =>
  formatDuration(state.inactivityThresholdMinutes)
);
const followUpResolutionThresholdLabel = computed(() =>
  formatDuration(state.followUpResolveAfterMinutes)
);
const initialActionTimingLabel = computed(() =>
  state.autoResolveMode === 'evaluated'
    ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.REVIEW_AFTER')
    : t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLVE_AFTER')
);

const selectedInactivityResolutionSummary = computed(() => {
  if (state.autoResolveMode === 'disabled') {
    return t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.SUMMARY.PENDING');
  }

  let resolutionSummary =
    state.autoResolveMode === 'evaluated'
      ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.SUMMARY.REVIEW', {
          duration: inactivityThresholdLabel.value,
        })
      : t(
          'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.SUMMARY.ALWAYS_RESOLVE',
          { duration: inactivityThresholdLabel.value }
        );

  if (state.autoResolveMode === 'evaluated' && state.followUpBeforeResolving) {
    resolutionSummary = `${resolutionSummary} ${t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.SUMMARY.FOLLOW_UP',
      { duration: followUpResolutionThresholdLabel.value }
    )}`;
  }

  if (state.sendInactivityResolutionMessage) return resolutionSummary;

  return `${resolutionSummary} ${t(
    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.DISABLED_SUMMARY'
  )}`;
});

const shouldShowInactivityDuration = computed(
  () => state.autoResolveMode !== 'disabled'
);
const shouldShowFollowUpSettings = computed(
  () => state.autoResolveMode === 'evaluated'
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

const followUpResolutionThresholdHours = computed({
  get: () => Math.floor(state.followUpResolveAfterMinutes / 60),
  set: hours => {
    const remainingMinutes = state.followUpResolveAfterMinutes % 60;
    const requestedMinutes = Number(hours) * 60 + remainingMinutes;
    state.followUpResolveAfterMinutes = Math.min(
      Math.max(requestedMinutes, 5),
      24 * 60
    );
  },
});

const followUpResolutionThresholdRemainingMinutes = computed({
  get: () => state.followUpResolveAfterMinutes % 60,
  set: minutes => {
    const completeHours = Math.floor(state.followUpResolveAfterMinutes / 60);
    const requestedMinutes = completeHours * 60 + Number(minutes);
    state.followUpResolveAfterMinutes = Math.min(
      Math.max(requestedMinutes, 5),
      24 * 60
    );
  },
});

const followUpResolutionMinuteOptions = computed(() => {
  return Array.from({ length: 12 }, (_, index) => {
    const minutes = index * 5;
    const hours = followUpResolutionThresholdHours.value;

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
  followUpResolveAfterMinutes: {
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
  followUpResolveAfterMinutes: getErrorMessage('followUpResolveAfterMinutes'),
}));

const handleInactivityResolutionUpdate = async () => {
  const validations = [v$.value.inactivityThresholdMinutes.$validate()];
  if (state.autoResolveMode === 'evaluated' && state.followUpBeforeResolving) {
    validations.push(v$.value.followUpResolveAfterMinutes.$validate());
  }
  if (
    shouldShowInactivityDuration.value &&
    state.sendInactivityResolutionMessage
  ) {
    validations.push(v$.value.resolutionMessage.$validate());
  }
  const result = await Promise.all(validations).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  emit('submit', {
    config: {
      ...props.assistant.config,
      auto_resolve_mode: state.autoResolveMode,
      auto_resolve_after: state.inactivityThresholdMinutes,
      follow_up_before_resolving: state.followUpBeforeResolving,
      follow_up_resolve_after: state.followUpResolveAfterMinutes,
      send_inactivity_resolution_message: state.sendInactivityResolutionMessage,
      resolution_message: state.resolutionMessage,
    },
  });
};

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.handoffMessage = config.handoff_message;
  state.resolutionMessage = config.resolution_message;
  state.instructions = config.instructions;
  state.autoResolveMode = config.auto_resolve_mode ?? 'evaluated';
  state.inactivityThresholdMinutes = config.auto_resolve_after ?? 60;
  state.followUpBeforeResolving = config.follow_up_before_resolving ?? false;
  state.followUpResolveAfterMinutes = config.follow_up_resolve_after ?? 60;
  state.sendInactivityResolutionMessage =
    config.send_inactivity_resolution_message ?? true;
};

const handleSystemMessagesUpdate = async () => {
  const validations = [v$.value.handoffMessage.$validate()];

  if (!isCaptainV2Enabled.value) {
    validations.push(
      v$.value.resolutionMessage.$validate(),
      v$.value.instructions.$validate()
    );
  }

  const result = await Promise.all(validations).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      handoff_message: state.handoffMessage,
    },
  };

  if (!isCaptainV2Enabled.value) {
    payload.config.resolution_message = state.resolutionMessage;
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
      class="flex flex-col border-b border-n-weak pb-6"
    >
      <button
        type="button"
        class="flex w-full items-center justify-between gap-4 text-left"
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
        class="flex flex-col gap-4 pt-4"
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
            {{ initialActionTimingLabel }}
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

        <div
          v-if="state.autoResolveMode === 'legacy'"
          class="flex items-start gap-2 rounded-lg bg-n-amber-3 p-3 text-sm text-n-amber-12"
        >
          <span class="i-lucide-triangle-alert mt-0.5 size-4 shrink-0" />
          <p>
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.ALWAYS_WARNING')
            }}
          </p>
        </div>

        <div
          v-if="state.autoResolveMode === 'disabled'"
          class="flex items-start gap-2 rounded-lg bg-n-blue-3 p-3 text-sm text-n-blue-12"
        >
          <span class="i-lucide-info mt-0.5 size-4 shrink-0" />
          <p>
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.PENDING_INFO')
            }}
          </p>
        </div>

        <SettingsToggleSection
          v-if="shouldShowFollowUpSettings"
          v-model="state.followUpBeforeResolving"
          :header="
            t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.TITLE')
          "
          :description="
            t(
              'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.DESCRIPTION'
            )
          "
        />

        <div
          v-if="shouldShowFollowUpSettings && state.followUpBeforeResolving"
          class="flex flex-col gap-2"
        >
          <p class="text-sm font-medium text-n-slate-12">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLVE_AFTER')
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
                v-model="followUpResolutionThresholdHours"
                :options="inactivityHourOptions"
                :error="formErrors.followUpResolveAfterMinutes"
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
                v-model="followUpResolutionThresholdRemainingMinutes"
                :options="followUpResolutionMinuteOptions"
                :error="formErrors.followUpResolveAfterMinutes"
                class="!w-full [&>select]:w-full"
              />
            </label>
          </div>
          <p
            v-if="formErrors.followUpResolveAfterMinutes"
            class="text-xs text-n-ruby-9"
          >
            {{ formErrors.followUpResolveAfterMinutes }}
          </p>
        </div>

        <SettingsToggleSection
          v-if="shouldShowInactivityDuration"
          v-model="state.sendInactivityResolutionMessage"
          :header="
            t(
              'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.TITLE'
            )
          "
          :description="
            t(
              'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.DESCRIPTION'
            )
          "
        >
          <template #editor>
            <Editor
              v-if="state.sendInactivityResolutionMessage"
              v-model="state.resolutionMessage"
              :placeholder="
                t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')
              "
              :message="formErrors.resolutionMessage"
              :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
              class="z-0"
            />
            <p v-else class="text-xs text-n-slate-11">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.RETAINED'
                )
              }}
            </p>
          </template>
        </SettingsToggleSection>

        <div>
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SAVE_INACTIVITY_SETTINGS')"
            @click="handleInactivityResolutionUpdate"
          />
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
      v-if="!isCaptainV2Enabled"
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
        :label="
          isCaptainV2Enabled
            ? t('CAPTAIN.ASSISTANTS.FORM.SAVE_HANDOFF_MESSAGE')
            : t('CAPTAIN.ASSISTANTS.FORM.UPDATE')
        "
        @click="handleSystemMessagesUpdate"
      />
    </div>
  </div>
</template>
