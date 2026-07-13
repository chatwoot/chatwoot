<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { processSteps } from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  task: { type: Object, required: true },
  compact: { type: Boolean, default: false },
});

const { t } = useI18n();
const steps = computed(() => processSteps(props.task));
</script>

<template>
  <div
    class="flex items-center gap-1 w-full"
    :class="compact ? 'py-1' : 'py-2'"
  >
    <template v-for="(step, index) in steps" :key="step.key">
      <div class="flex flex-col items-center gap-1 min-w-0 flex-1">
        <div
          class="rounded-full border-2 flex items-center justify-center transition-colors"
          :class="[
            compact ? 'size-4' : 'size-5',
            step.done
              ? 'border-n-teal-9 bg-n-teal-9 text-white'
              : step.active
                ? 'border-n-blue-9 bg-n-blue-3'
                : 'border-n-weak bg-n-solid-2',
          ]"
        >
          <span
            v-if="step.done"
            class="i-lucide-check"
            :class="compact ? 'size-2.5' : 'size-3'"
          />
        </div>
        <span
          class="text-center text-n-slate-11 leading-tight truncate w-full"
          :class="compact ? 'text-[10px]' : 'text-xxs'"
        >
          {{ t(`INTERNAL_TASKS.PROCESS.${step.key.toUpperCase()}`) }}
        </span>
      </div>
      <div
        v-if="index < steps.length - 1"
        class="h-px flex-1 mb-4"
        :class="step.done ? 'bg-n-teal-8' : 'bg-n-weak'"
      />
    </template>
  </div>
</template>
