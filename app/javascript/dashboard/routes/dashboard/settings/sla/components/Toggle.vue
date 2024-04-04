<script setup>
import { ref } from 'vue';

const props = defineProps({
  value: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['input']);
const isChecked = ref(props.value);

const toggleCheckbox = () => {
  isChecked.value = !isChecked.value;
  emit('input', isChecked.value);
};
</script>

<template>
  <label class="relative inline-block h-4 w-7">
    <input
      class="hidden peer"
      type="checkbox"
      :checked="isChecked"
      @click="toggleCheckbox"
    />
    <div
      :class="[
        'absolute inset-0 p-0.5 transition-all ease-in-out duration-200 rounded-full cursor-pointer slider bg-slate-100',
        'peer-focus:shadow-sm peer-checked:bg-woot-500 peer-checked:before:translate-x-3',
        'before:absolute before:rounded-full before:content-[ ] before:top-0.5 before:left-0.5 before:h-3 before:w-3 before:bg-white before:transition-all before:duration-200',
      ]"
    />
  </label>
</template>
