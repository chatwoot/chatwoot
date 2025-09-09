<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();

const fairDistributionLimit = defineModel('fairDistributionLimit', {
  type: Number,
  default: 0,
});

const fairDistributionWindow = defineModel('fairDistributionWindow', {
  type: Number,
  default: 0,
});

const windowUnit = ref(DURATION_UNITS.MINUTES);

// onUpdated(() => {
//   if (fairDistributionWindow.value % (24 * 60) === 0) {
//     windowUnit.value = DURATION_UNITS.DAYS;
//   } else if (fairDistributionWindow.value % 60 === 0) {
//     windowUnit.value = DURATION_UNITS.HOURS;
//   } else {
//     windowUnit.value = DURATION_UNITS.MINUTES;
//   }
// });
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
      <div class="flex items-center gap-2 flex-1">
        <DurationInput
          v-model:model-value="fairDistributionWindow"
          v-model:unit="windowUnit"
          class="flex items-center gap-2"
        />
      </div>
    </div>
  </div>
</template>
