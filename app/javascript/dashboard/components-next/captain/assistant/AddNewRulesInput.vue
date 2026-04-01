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
    class="flex h-16 items-center gap-3 rounded-xl border border-outline-variant/10 bg-surface-container-lowest py-3 ltr:pl-3 ltr:pr-4 rtl:pl-4 rtl:pr-3"
  >
    <Icon
      icon="i-lucide-plus"
      class="size-5 flex-shrink-0 text-on-surface-variant"
    />

    <InlineInput
      v-model="modelValue"
      :placeholder="placeholder"
      @keyup.enter="onClickAdd"
    />
    <Button
      :label="label"
      ghost
      xs
      class="!text-sm flex-shrink-0 text-on-surface-variant"
      @click="onClickAdd"
    />
  </div>
</template>
