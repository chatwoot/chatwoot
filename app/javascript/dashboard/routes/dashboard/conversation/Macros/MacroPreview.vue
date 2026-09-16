<script setup>
import { computed } from 'vue';
import { useMacros } from 'dashboard/composables/useMacros';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
});

const { resolveMacroActions } = useMacros();

const resolvedMacro = computed(() => resolveMacroActions(props.macro));
</script>

<template>
  <div
    class="macro-preview absolute border border-n-weak max-h-[22.5rem] z-50 w-64 rounded-md bg-n-alpha-3 backdrop-blur-[100px] shadow-lg bottom-8 end-8 overflow-y-auto p-4 text-start"
  >
    <h6 class="mb-4 text-sm text-n-slate-12">
      {{ macro.name }}
    </h6>
    <div
      v-for="(action, i) in resolvedMacro"
      :key="i"
      class="relative ps-4 macro-block"
    >
      <div
        v-if="i !== macro.actions.length - 1"
        class="top-[0.390625rem] absolute -bottom-1 start-0 w-px bg-n-slate-6"
      />
      <div
        class="absolute -start-[0.21875rem] top-[0.2734375rem] w-2 h-2 rounded-full bg-n-solid-1 border-2 border-solid border-n-weak dark:border-n-slate-6"
      />
      <p class="mb-1 text-xs text-n-slate-11">
        {{ $t(`MACROS.ACTIONS.${action.actionName}`) }}
      </p>
      <p class="text-n-slate-12 text-sm">{{ action.actionValue }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.macro-preview {
  .macro-block {
    &:not(:last-child) {
      @apply pb-2;
    }
  }
}
</style>
