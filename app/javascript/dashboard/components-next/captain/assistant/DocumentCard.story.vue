<script setup>
import DocumentCard from './DocumentCard.vue';
import { documentsList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';
</script>

<template>
  <Story
    title="Captain/Assistant/DocumentCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Document Card">
      <div
        v-for="(doc, index) in documentsList"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <DocumentCard
          :id="doc.id"
          :name="doc.name"
          :external-link="doc.external_link"
          :assistant="doc.assistant"
          :created-at="doc.created_at"
        />
      </div>
    </Variant>
  </Story>
</template>
