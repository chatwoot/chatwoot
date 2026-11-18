<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { businessHoursSummary } from './businessHours';
import { useLocale } from 'shared/composables/useLocale';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  help: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['openBusinessHours']);

const applyHours = defineModel({ type: Boolean });

const { t } = useI18n();
const { resolvedLocale } = useLocale();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.OUT_OF_HOURS.${key}`);

const hoursOn = computed(() => !!props.inbox.working_hours_enabled);
const hoursSummary = computed(() =>
  businessHoursSummary(props.inbox.working_hours, {
    locale: resolvedLocale.value,
    allDayLabel: label('ALL_DAY'),
  })
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between gap-4">
      <span class="flex flex-col gap-0.5">
        <span class="text-body-main font-medium text-n-slate-12">
          {{ label('APPLY') }}
        </span>
        <span class="text-body-main text-n-slate-11">
          {{ help }}
        </span>
      </span>
      <ToggleSwitch v-model="applyHours" />
    </div>

    <div
      v-if="!hoursOn"
      class="flex flex-col items-start gap-1 px-3 py-2 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-6 text-body-main text-n-slate-12"
    >
      {{ applyHours ? label('HOURS_OFF_APPLIED') : label('HOURS_OFF') }}
      <NextButton
        :label="label('GO_TO_HOURS')"
        link
        amber
        sm
        @click="emit('openBusinessHours')"
      />
    </div>
    <div
      v-else-if="applyHours"
      class="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-2 rounded-lg bg-n-alpha-black2 text-body-main text-n-slate-12"
    >
      <span>
        <span class="font-medium">{{ label('INBOX_HOURS') }}</span>
        {{ hoursSummary || label('ALWAYS_CLOSED') }} · {{ inbox.timezone }}
      </span>
      <NextButton
        :label="label('EDIT_HOURS')"
        link
        sm
        @click="emit('openBusinessHours')"
      />
    </div>
  </div>
</template>
