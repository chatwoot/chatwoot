<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

defineProps({
  placeholder: { type: String, required: true },
});

const query = defineModel({ type: String, default: '' });
</script>

<template>
  <Input
    v-model="query"
    type="search"
    :placeholder="placeholder"
    size="sm"
    :custom-input-class="[
      '[&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 rtl:!pr-8',
    ]"
    class="w-full sm:w-56"
  >
    <template #prefix>
      <Icon
        icon="i-lucide-search"
        class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
      />
    </template>
  </Input>
</template>
