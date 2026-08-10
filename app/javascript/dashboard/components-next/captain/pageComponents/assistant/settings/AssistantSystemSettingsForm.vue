<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { maxValue, minLength, minValue, required } from '@vuelidate/validators';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
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

const initialState = {
  handoffMessage: '',
  resolutionMessage: '',
  instructions: '',
  inactivityThresholdMinutes: 60,
  sendInactivityResolutionMessage: true,
};

const state = reactive({ ...initialState });

const MINUTES_PER_HOUR = 60;
const INACTIVITY_STEP_MINUTES = 5;
const MIN_INACTIVITY_MINUTES = 5;
const MAX_INACTIVITY_MINUTES = 24 * MINUTES_PER_HOUR;
const MAX_INACTIVITY_HOURS = MAX_INACTIVITY_MINUTES / MINUTES_PER_HOUR;

const hoursPart = totalMinutes => Math.floor(totalMinutes / MINUTES_PER_HOUR);
const minutesPart = totalMinutes => totalMinutes % MINUTES_PER_HOUR;

const setInactivityThreshold = (hours, minutes) => {
  state.inactivityThresholdMinutes = Math.min(
    Math.max(hours * MINUTES_PER_HOUR + minutes, MIN_INACTIVITY_MINUTES),
    MAX_INACTIVITY_MINUTES
  );
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

const inactivityHourOptions = computed(() =>
  Array.from({ length: MAX_INACTIVITY_HOURS + 1 }, (_, hours) => ({
    value: hours,
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS_SHORT',
      { count: hours }
    ),
  }))
);

const inactivityMinuteOptions = computed(() => {
  const hours = inactivityThresholdHours.value;

  return Array.from(
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
});

const validationRules = {
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
  instructions: { minLength: minLength(1) },
  inactivityThresholdMinutes: {
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
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.handoffMessage = config.handoff_message;
  state.resolutionMessage = config.resolution_message;
  state.instructions = config.instructions;
  state.inactivityThresholdMinutes = config.auto_resolve_after ?? 60;
  state.sendInactivityResolutionMessage =
    config.send_inactivity_resolution_message ?? true;
};

const handleSystemMessagesUpdate = async () => {
  const validations = [v$.value.handoffMessage.$validate()];

  if (isCaptainV2Enabled.value) {
    validations.push(v$.value.inactivityThresholdMinutes.$validate());
    if (state.sendInactivityResolutionMessage) {
      validations.push(v$.value.resolutionMessage.$validate());
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
      auto_resolve_after: state.inactivityThresholdMinutes,
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
    >
      <div class="flex w-full flex-col gap-4 py-2">
        <div
          class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
        >
          <span class="text-body-main text-n-slate-12">
            {{
              t('CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_LABEL')
            }}
          </span>
          <div class="flex shrink-0 gap-2">
            <Select
              v-model="inactivityThresholdHours"
              :options="inactivityHourOptions"
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

        <div class="flex items-center justify-between gap-3">
          <span class="text-body-main text-n-slate-12">
            {{
              t(
                'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.TITLE'
              )
            }}
          </span>
          <Switch
            v-model="state.sendInactivityResolutionMessage"
            :aria-label="
              t(
                'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.TITLE'
              )
            "
          />
        </div>
      </div>
      <template v-if="state.sendInactivityResolutionMessage" #editor>
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
