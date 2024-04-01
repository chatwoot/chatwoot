<script setup>
import { ref } from 'vue';

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue']);

const isChecked = ref(props.modelValue);

const toggleCheckbox = () => {
  isChecked.value = !isChecked.value;
  emit('update:modelValue', isChecked.value);
};
</script>

<template>
  <label class="relative inline-block h-4 w-7">
    <input class="hidden" type="checkbox" @click="toggleCheckbox" />
    <div
      class="absolute inset-0 p-0.5 transition-all ease-in-out duration-200 rounded-full cursor-pointer slider bg-slate-100"
    />
  </label>
</template>

<style>
.slider:before {
  position: absolute;
  border-radius: 50%;
  content: '';
  top: 2px;
  left: 2px;
  height: calc(16px - 4px); /* 16px - 2 * 2px padding */
  width: calc(16px - 4px);
  background-color: white;
  -webkit-transition: 0.4s;
  transition: 0.4s;
}

input:checked + .slider {
  @apply bg-woot-500;
}

input:focus + .slider {
  box-shadow: 0 0 1px #101010;
}

input:checked + .slider:before {
  transform: translateX(12px);
}
</style>
