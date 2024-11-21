<script setup>
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  showActions: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['add']);
</script>

<template>
  <BaseSettingsHeader
    :title="$t('SLA.HEADER')"
    :description="$t('SLA.DESCRIPTION')"
    :link-text="$t('SLA.LEARN_MORE')"
    feature-name="sla"
  >
    <template v-if="showActions" #actions>
      <Button
        :label="$t('SLA.ADD_ACTION')"
        icon="i-lucide-plus"
        size="sm"
        @click="$emit('add')"
      />
    </template>
  </BaseSettingsHeader>
</template>
