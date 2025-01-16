<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DocumentCard from 'dashboard/components-next/captain/assistant/DocumentCard.vue';
import { documentsList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <DocumentCard
          v-for="(document, index) in documentsList.slice(0, 5)"
          :id="document.id"
          :key="`document-${index}`"
          :name="document.name"
          :assistant="document.assistant"
          :external-link="document.external_link"
          :created-at="document.created_at"
        />
      </div>
    </template>
    <template #actions>
      <Button :label="buttonLabel" icon="i-lucide-plus" @click="onClick" />
    </template>
  </EmptyStateLayout>
</template>
