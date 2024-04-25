<template>
  <div>
    <label
      class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900 d"
    >
      {{ label }}
    </label>
    <div class="flex flex-col gap-2">
      <div
        v-for="item in items"
        :key="item.id"
        class="flex flex-row items-start gap-2"
      >
        <input
          :id="item.id"
          v-model="item.model"
          type="checkbox"
          :value="item.value"
          class="mt-1 dark:border-slate-600 checked:bg-primary-600 dark:checked:bg-primary-600 shadow appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
          @input="onChange"
        />
        <label class="text-sm font-normal text-ash-900">
          {{ item.label }}
        </label>
      </div>
    </div>
  </div>
</template>
<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['change']);
const onChange = e => {
  emit('change', e);
};
</script>
