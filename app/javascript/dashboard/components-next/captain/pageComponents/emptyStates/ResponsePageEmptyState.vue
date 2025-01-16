<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import { responsesList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

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
        <ResponseCard
          v-for="(response, index) in responsesList.slice(0, 5)"
          :id="response.id"
          :key="`response-${index}`"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :assistant="response.assistant"
          :created-at="response.created_at"
          :updated-at="response.created_at"
        />
      </div>
    </template>
    <template #actions>
      <Button :label="buttonLabel" icon="i-lucide-plus" @click="onClick" />
    </template>
  </EmptyStateLayout>
</template>
