<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['add']);

const addLabel = () => {
  emit('add');
};
</script>

<template>
  <Button
    faded
    xs
    icon="i-lucide-plus"
    class="mb-0.5 ltr:mr-0.5 rtl:ml-0.5 !rounded-[4px]"
    :label="$t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON')"
    @click="addLabel"
  />
</template>
