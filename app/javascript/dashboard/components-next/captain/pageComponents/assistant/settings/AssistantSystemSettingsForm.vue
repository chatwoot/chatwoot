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
  inactivityThresholdMinutes: 60,
  sendInactivityResolutionMessage: true,
};

const state = reactive({ ...initialState });
const isInactivityResolutionSettingsExpanded = ref(false);

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
  const resolutionSummary = t(
    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.CURRENT_SETTING',
    {
      duration: inactivityThresholdLabel.value,
    }
  );

  if (state.sendInactivityResolutionMessage) return resolutionSummary;

  return `${resolutionSummary} ${t(
    'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.RESOLUTION_MESSAGE.DISABLED_SUMMARY'
  )}`;
});

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

const handleInactivityResolutionUpdate = async () => {
  const validations = [v$.value.inactivityThresholdMinutes.$validate()];
  if (state.sendInactivityResolutionMessage) {
    validations.push(v$.value.resolutionMessage.$validate());
  }
  const result = await Promise.all(validations).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  emit('submit', {
    config: {
      ...props.assistant.config,
      auto_resolve_after: state.inactivityThresholdMinutes,
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
  state.inactivityThresholdMinutes = config.auto_resolve_after ?? 60;
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
        <div class="flex flex-col gap-2">
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

        <SettingsToggleSection
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
          <template v-if="state.sendInactivityResolutionMessage" #editor>
            <Editor
              v-model="state.resolutionMessage"
              :placeholder="
                t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')
              "
              :message="formErrors.resolutionMessage"
              :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
              class="z-0"
            />
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
