<template>
  <div>
    <label
      class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900"
    >
      {{ label }}
    </label>
    <div
      class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-md border-ash-200"
    >
      <div
        v-for="option in options"
        :key="option.value"
        class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow"
        :class="{
          'border-r-0': option.value === options[options.length - 1].value,
        }"
      >
        <input
          :id="`radio-${option.value}`"
          v-model="selectedValue"
          class="shadow cursor-pointer grid place-items-center border-2 border-ash-200 appearance-none rounded-full w-5 h-5 checked:bg-primary-600 before:content-[''] before:bg-primary-600 before:border-4 before:rounded-full before:border-ash-25 checked:before:w-[16px] checked:before:h-[16px] checked:border checked:border-primary-600"
          type="radio"
          :value="option.value"
          @change="emitChange"
        />
        <label
          :for="`radio-${option.value}`"
          class="text-sm font-medium text-ash-900"
          :class="{ 'text-ash-400': selectedValue !== option.value }"
        >
          {{ option.label }}
        </label>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  value: {
    type: String,
    default: 'all',
  },
});

const options = [
  { value: 'all', label: 'All' },
  { value: 'mentions', label: 'Mentions' },
  { value: 'none', label: 'None' },
];

const selectedValue = ref(props.value);

watch(
  () => props.value,
  newValue => {
    selectedValue.value = newValue;
  }
);

const emit = defineEmits(['update']);
const emitChange = e => {
  emit('update', e);
};
</script>
