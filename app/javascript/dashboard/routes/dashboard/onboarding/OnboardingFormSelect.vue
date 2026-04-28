<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  placeholder: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
});

defineEmits(['update:modelValue']);
</script>

<template>
  <div class="relative flex items-center justify-end">
    <select
      :value="modelValue"
      class="reset-base text-sm text-right bg-transparent border-0 p-0 m-0 cursor-pointer appearance-none pr-[17px] focus:outline-none focus:ring-0"
      :class="[
        modelValue ? 'text-n-slate-12' : 'text-n-slate-9',
        { 'animate-shake': hasError },
      ]"
      @change="$emit('update:modelValue', $event.target.value)"
    >
      <option v-if="placeholder" value="" disabled>
        {{ placeholder }}
      </option>
      <option v-for="opt in options" :key="opt.value" :value="opt.value">
        {{ opt.label }}
      </option>
    </select>
    <Icon
      icon="i-lucide-chevron-down"
      class="pointer-events-none absolute right-0 top-1/2 -translate-y-1/2 text-n-slate-9"
    />
  </div>
</template>
