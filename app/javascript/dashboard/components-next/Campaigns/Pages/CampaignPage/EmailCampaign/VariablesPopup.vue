<script setup>
defineProps({
  modelValue: Boolean,
  variables: Object,
  x: Number,
  y: Number,
});

defineEmits(['update:modelValue']);
</script>

<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 z-50"
    @click.self.stop="$emit('update:modelValue', false)"
  >
    <div
      class="absolute bg-white text-black dark:bg-[#1b1c21] dark:text-white rounded-xl shadow-lg p-4 w-[500px]"
      :style="{ top: `${y}px`, left: `${x}px` }"
    >
      <h2 class="text-lg font-semibold mb-4">Contact variables</h2>

      <div
        v-for="(value, key) in variables"
        :key="key"
        class="flex items-center mb-2"
      >
        <div
          class="text-xs px-2 py-1 rounded bg-slate-100 text-slate-700 font-mono truncate"
          style="width: 160px"
        >
          {{ key }}
        </div>
        <div class="flex-1" />
        <div class="text-sm ml-3 text-right" style="width: 240px">
          {{ value }}
        </div>
      </div>

      <button
        class="absolute top-2 right-2 text-black text-lg"
        aria-label="Close"
        @click.stop="$emit('update:modelValue', false)"
      >
        ✕
      </button>
    </div>
  </div>
</template>
