<script setup>
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

const isDelayed = defineModel({ type: Boolean, default: false });

const RUN_TYPES = [
  { id: 'automation_run_instantly', key: 'INSTANT', delayed: false },
  { id: 'automation_run_after_wait', key: 'WAIT', delayed: true },
];

const onSelect = id => {
  isDelayed.value = RUN_TYPES.find(runType => runType.id === id).delayed;
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <label class="mb-0">
      {{ $t('AUTOMATION.ADD.FORM.RUN_TYPE.LABEL') }}
    </label>
    <div class="grid gap-3 sm:grid-cols-2">
      <RadioCard
        v-for="runType in RUN_TYPES"
        :id="runType.id"
        :key="runType.id"
        :label="$t(`AUTOMATION.ADD.FORM.RUN_TYPE.OPTIONS.${runType.key}.LABEL`)"
        :description="
          $t(`AUTOMATION.ADD.FORM.RUN_TYPE.OPTIONS.${runType.key}.DESCRIPTION`)
        "
        :is-active="isDelayed === runType.delayed"
        @select="onSelect"
      />
    </div>
  </div>
</template>
