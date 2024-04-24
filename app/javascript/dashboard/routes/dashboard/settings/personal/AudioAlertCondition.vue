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
          class="mb-0 mt-0.5 border-[1.5px] flex-shrink-0 shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-primary-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
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
