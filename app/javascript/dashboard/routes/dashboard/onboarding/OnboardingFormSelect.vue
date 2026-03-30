<script setup>
defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  placeholder: { type: String, default: '' },
});

defineEmits(['update:modelValue']);
</script>

<template>
  <select
    :value="modelValue"
    class="reset-base text-sm text-right bg-transparent border-0 p-0 m-0 cursor-pointer appearance-none bg-[url('data:image/svg+xml,%3Csvg%20width=%279%27%20height=%275%27%20viewBox=%270%200%209%205%27%20fill=%27none%27%20xmlns=%27http://www.w3.org/2000/svg%27%3E%3Cpath%20d=%27M0.583252%200.583984L4.08325%204.08398L7.58325%200.583984%27%20stroke=%27%237E808A%27%20stroke-width=%271.16667%27%20stroke-linecap=%27round%27%20stroke-linejoin=%27round%27/%3E%3C/svg%3E')] bg-no-repeat bg-[length:9px_5px] bg-[right_0_center] pr-[17px] focus:outline-none focus:ring-0"
    :class="modelValue ? 'text-n-slate-12' : 'text-n-slate-9'"
    @change="$emit('update:modelValue', $event.target.value)"
  >
    <option v-if="placeholder" value="" disabled>
      {{ placeholder }}
    </option>
    <option v-for="opt in options" :key="opt.value" :value="opt.value">
      {{ opt.label }}
    </option>
  </select>
</template>
