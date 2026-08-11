<script setup>
import { computed, reactive, watch } from 'vue';
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

const MINUTES_PER_HOUR = 60;
const INACTIVITY_STEP_MINUTES = 5;
const MIN_INACTIVITY_MINUTES = 5;
const MAX_INACTIVITY_MINUTES = 24 * MINUTES_PER_HOUR;
const MAX_INACTIVITY_HOURS = MAX_INACTIVITY_MINUTES / MINUTES_PER_HOUR;

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

const shouldShowInactivityDuration = computed(
  () => state.autoResolveMode !== 'disabled'
);
const shouldShowFollowUpSettings = computed(
  () => state.autoResolveMode === 'evaluated'
);
const initialActionTimingLabel = computed(() =>
  state.autoResolveMode === 'evaluated'
    ? t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.REVIEW_AFTER')
    : t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLVE_AFTER')
);

const hoursPart = totalMinutes => Math.floor(totalMinutes / MINUTES_PER_HOUR);
const minutesPart = totalMinutes => totalMinutes % MINUTES_PER_HOUR;

const clampThreshold = (hours, minutes) =>
  Math.min(
    Math.max(hours * MINUTES_PER_HOUR + minutes, MIN_INACTIVITY_MINUTES),
    MAX_INACTIVITY_MINUTES
  );

const setInactivityThreshold = (hours, minutes) => {
  state.inactivityThresholdMinutes = clampThreshold(hours, minutes);
};

const setFollowUpResolutionThreshold = (hours, minutes) => {
  state.followUpResolveAfterMinutes = clampThreshold(hours, minutes);
};

const inactivityThresholdHours = computed({
  get: () => hoursPart(state.inactivityThresholdMinutes),
  set: hours =>
    setInactivityThreshold(
      Number(hours),
      minutesPart(state.inactivityThresholdMinutes)
    ),
});

const inactivityThresholdRemainingMinutes = computed({
  get: () => minutesPart(state.inactivityThresholdMinutes),
  set: minutes =>
    setInactivityThreshold(
      hoursPart(state.inactivityThresholdMinutes),
      Number(minutes)
    ),
});

const followUpResolutionThresholdHours = computed({
  get: () => hoursPart(state.followUpResolveAfterMinutes),
  set: hours =>
    setFollowUpResolutionThreshold(
      Number(hours),
      minutesPart(state.followUpResolveAfterMinutes)
    ),
});

const followUpResolutionThresholdRemainingMinutes = computed({
  get: () => minutesPart(state.followUpResolveAfterMinutes),
  set: minutes =>
    setFollowUpResolutionThreshold(
      hoursPart(state.followUpResolveAfterMinutes),
      Number(minutes)
    ),
});

const thresholdHourOptions = computed(() =>
  Array.from({ length: MAX_INACTIVITY_HOURS + 1 }, (_, hours) => ({
    value: hours,
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS_SHORT',
      { count: hours }
    ),
  }))
);

const thresholdMinuteOptions = hours =>
  Array.from(
    { length: MINUTES_PER_HOUR / INACTIVITY_STEP_MINUTES },
    (_, index) => {
      const minutes = index * INACTIVITY_STEP_MINUTES;

      return {
        value: minutes,
        label: t(
          'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES_SHORT',
          { count: minutes }
        ),
        disabled:
          (hours === 0 && minutes === 0) ||
          (hours === MAX_INACTIVITY_HOURS && minutes !== 0),
      };
    }
  );

const inactivityMinuteOptions = computed(() =>
  thresholdMinuteOptions(inactivityThresholdHours.value)
);
const followUpResolutionMinuteOptions = computed(() =>
  thresholdMinuteOptions(followUpResolutionThresholdHours.value)
);

const validationRules = {
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
  instructions: { minLength: minLength(1) },
  inactivityThresholdMinutes: {
    required,
    minValue: minValue(MIN_INACTIVITY_MINUTES),
    maxValue: maxValue(MAX_INACTIVITY_MINUTES),
  },
  followUpResolveAfterMinutes: {
    required,
    minValue: minValue(MIN_INACTIVITY_MINUTES),
    maxValue: maxValue(MAX_INACTIVITY_MINUTES),
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

  if (isCaptainV2Enabled.value) {
    if (shouldShowInactivityDuration.value) {
      validations.push(v$.value.inactivityThresholdMinutes.$validate());

      if (state.sendInactivityResolutionMessage) {
        validations.push(v$.value.resolutionMessage.$validate());
      }
    }

    if (shouldShowFollowUpSettings.value && state.followUpBeforeResolving) {
      validations.push(v$.value.followUpResolveAfterMinutes.$validate());
    }
  } else {
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

  if (isCaptainV2Enabled.value) {
    Object.assign(payload.config, {
      auto_resolve_mode: state.autoResolveMode,
      auto_resolve_after: state.inactivityThresholdMinutes,
      follow_up_before_resolving: state.followUpBeforeResolving,
      follow_up_resolve_after: state.followUpResolveAfterMinutes,
      send_inactivity_resolution_message: state.sendInactivityResolutionMessage,
      resolution_message: state.resolutionMessage,
    });
  } else {
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
    <SettingsToggleSection
      v-if="isCaptainV2Enabled"
      hide-toggle
      :header="t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TITLE')"
      :description="
        t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DESCRIPTION')
      "
    >
      <div class="flex w-full flex-col gap-4 pt-3">
        <div
          class="flex flex-col gap-3"
          role="radiogroup"
          :aria-label="
            t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.MODE_LABEL')
          "
        >
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

        <div
          v-if="shouldShowInactivityDuration"
          class="flex flex-col gap-3 border-t border-n-weak pt-4"
        >
          <div
            class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between"
          >
            <span class="text-body-main font-medium text-n-slate-12">
              {{ initialActionTimingLabel }}
            </span>
            <div class="flex shrink-0 gap-2">
              <Select
                v-model="inactivityThresholdHours"
                :options="thresholdHourOptions"
                :error="formErrors.inactivityThresholdMinutes"
                :aria-label="
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS_ARIA_LABEL'
                  )
                "
                class="[&>select]:min-w-24"
              />
              <Select
                v-model="inactivityThresholdRemainingMinutes"
                :options="inactivityMinuteOptions"
                :error="formErrors.inactivityThresholdMinutes"
                :aria-label="
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES_ARIA_LABEL'
                  )
                "
                class="[&>select]:min-w-28"
              />
            </div>
          </div>
          <p
            v-if="formErrors.inactivityThresholdMinutes"
            class="mb-0 text-xs text-n-ruby-9"
          >
            {{ formErrors.inactivityThresholdMinutes }}
          </p>
        </div>

        <div
          v-if="state.autoResolveMode === 'legacy'"
          class="flex items-start gap-2 rounded-lg bg-n-amber-3 p-3 text-sm text-n-amber-12"
        >
          <span class="i-lucide-triangle-alert mt-0.5 size-4 shrink-0" />
          <p class="mb-0">
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
          <p class="mb-0">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.PENDING_INFO')
            }}
          </p>
        </div>

        <div
          v-if="shouldShowFollowUpSettings"
          class="flex flex-col gap-4 border-t border-n-weak pt-4"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="flex flex-col gap-1">
              <span class="text-body-main font-medium text-n-slate-12">
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.TITLE'
                  )
                }}
              </span>
              <span class="text-body-main text-n-slate-11">
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.DESCRIPTION'
                  )
                }}
              </span>
            </div>
            <Switch
              v-model="state.followUpBeforeResolving"
              :aria-label="
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.TITLE'
                )
              "
            />
          </div>

          <div
            v-if="state.followUpBeforeResolving"
            class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between"
          >
            <span class="text-body-main font-medium text-n-slate-12">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.RESOLVE_AFTER'
                )
              }}
            </span>
            <div class="flex shrink-0 gap-2">
              <Select
                v-model="followUpResolutionThresholdHours"
                :options="thresholdHourOptions"
                :error="formErrors.followUpResolveAfterMinutes"
                :aria-label="
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.DURATION_HOURS_ARIA_LABEL'
                  )
                "
                class="[&>select]:min-w-24"
              />
              <Select
                v-model="followUpResolutionThresholdRemainingMinutes"
                :options="followUpResolutionMinuteOptions"
                :error="formErrors.followUpResolveAfterMinutes"
                :aria-label="
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.FOLLOW_UP.DURATION_MINUTES_ARIA_LABEL'
                  )
                "
                class="[&>select]:min-w-28"
              />
            </div>
          </div>
          <p
            v-if="formErrors.followUpResolveAfterMinutes"
            class="mb-0 text-xs text-n-ruby-9"
          >
            {{ formErrors.followUpResolveAfterMinutes }}
          </p>
        </div>

        <div
          v-if="shouldShowInactivityDuration"
          class="flex flex-col gap-2 border-t border-n-weak pt-4"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="flex flex-col gap-1">
              <span class="text-body-main font-medium text-n-slate-12">
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.TITLE'
                  )
                }}
              </span>
              <span class="text-body-main text-n-slate-11">
                {{
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.DESCRIPTION'
                  )
                }}
              </span>
            </div>
            <Switch
              v-model="state.sendInactivityResolutionMessage"
              :aria-label="
                t(
                  'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.TITLE'
                )
              "
            />
          </div>
          <p
            v-if="!state.sendInactivityResolutionMessage"
            class="mb-0 text-xs text-n-slate-11"
          >
            {{
              t(
                'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.RETAINED'
              )
            }}
          </p>
        </div>
      </div>

      <template
        v-if="
          shouldShowInactivityDuration && state.sendInactivityResolutionMessage
        "
        #editor
      >
        <Editor
          v-model="state.resolutionMessage"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')
          "
          :message="formErrors.resolutionMessage"
          :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
          class="z-0 [&_.editor-wrapper]:!min-h-32 [&_.editor-wrapper]:!border-0 [&_.editor-wrapper]:!bg-transparent [&_.editor-wrapper]:!p-0"
        />
      </template>
    </SettingsToggleSection>

    <SettingsToggleSection
      hide-toggle
      :header="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.LABEL')"
    >
      <template #editor>
        <Editor
          v-model="state.handoffMessage"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.PLACEHOLDER')
          "
          :message="formErrors.handoffMessage"
          :message-type="formErrors.handoffMessage ? 'error' : 'info'"
          class="z-0 [&_.editor-wrapper]:!min-h-32 [&_.editor-wrapper]:!border-0 [&_.editor-wrapper]:!bg-transparent [&_.editor-wrapper]:!p-0"
        />
      </template>
    </SettingsToggleSection>

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
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleSystemMessagesUpdate"
      />
    </div>
  </div>
</template>
