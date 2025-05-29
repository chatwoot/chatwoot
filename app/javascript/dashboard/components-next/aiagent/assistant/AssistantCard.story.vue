<script setup>
import AssistantCard from './AssistantCard.vue';
import { assistantsList } from 'dashboard/components-next/aiagent/pageComponents/emptyStates/aiagentEmptyStateContent.js';
</script>

<template>
  <Story
    title="Aiagent/Assistant/AssistantCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Assistant Card">
      <div
        v-for="(assistant, index) in assistantsList"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <AssistantCard
          :id="assistant.id"
          :name="assistant.name"
          :description="assistant.description"
          :updated-at="assistant.updated_at || assistant.created_at"
          :created-at="assistant.created_at"
        />
      </div>
    </Variant>
  </Story>
</template>
