<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();

const fairDistributionLimit = defineModel('fairDistributionLimit', {
  type: Number,
  default: 100,
  set(value) {
    return Number(value) || 0;
  },
});

const fairDistributionWindow = defineModel('fairDistributionWindow', {
  type: Number,
  default: 3600,
  set(value) {
    return Number(value) || 0;
  },
});

const windowUnit = ref(DURATION_UNITS.MINUTES);

const detectUnit = minutes => {
  const m = Number(minutes) || 0;
  if (m === 0) return DURATION_UNITS.MINUTES;
  if (m % (24 * 60) === 0) return DURATION_UNITS.DAYS;
  if (m % 60 === 0) return DURATION_UNITS.HOURS;
  return DURATION_UNITS.MINUTES;
};

onMounted(() => {
  windowUnit.value = detectUnit(fairDistributionWindow.value);
});
</script>

<template>
  <div
    class="flex items-start xl:items-center flex-col md:flex-row gap-4 lg:gap-3 bg-n-solid-1 p-4 outline outline-1 outline-n-weak rounded-xl"
  >
    <div class="flex items-center gap-3">
      <label class="text-sm font-medium text-n-slate-12">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.INPUT_MAX'
          )
        }}
      </label>
      <div class="flex-1">
        <Input
          v-model="fairDistributionLimit"
          type="number"
          placeholder="100"
          max="100000"
          class="w-full"
        />
      </div>
    </div>

    <div class="flex sm:flex-row flex-col items-start sm:items-center gap-4">
      <label class="text-sm font-medium text-n-slate-12">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.DURATION'
          )
        }}
      </label>

      <div
        class="flex items-center gap-2 flex-1 [&>select]:!bg-n-alpha-2 [&>select]:!outline-none [&>select]:hover:brightness-110"
      >
        <!-- allow 10 mins to 999 days -->
        <DurationInput
          v-model:model-value="fairDistributionWindow"
          v-model:unit="windowUnit"
          :min="10"
          :max="1438560"
        />
      </div>
    </div>
  </div>
</template>
