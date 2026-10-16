<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  maxLength: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits(['add']);

const modelValue = defineModel({
  type: String,
  default: '',
});

const onClickAdd = () => {
  if (!modelValue.value?.trim()) return;
  emit('add', modelValue.value.trim());
  modelValue.value = '';
};
</script>

<template>
  <div
    class="flex h-16 items-center gap-3 rounded-xl bg-n-solid-2 py-3 ps-3 pe-4 outline outline-1 outline-n-container -outline-offset-1"
  >
    <Icon icon="i-lucide-plus" class="text-n-slate-10 size-5 flex-shrink-0" />

    <InlineInput
      v-model="modelValue"
      :placeholder="placeholder"
      :max-length="maxLength"
      @keyup.enter="onClickAdd"
    />
    <Button
      :label="label"
      ghost
      xs
      slate
      class="!text-sm !text-n-slate-11 flex-shrink-0"
      @click="onClickAdd"
    />
  </div>
</template>
