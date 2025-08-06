<template>
  <div class="flex-1 overflow-hidden">
    <!-- Header -->
    <div class="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 px-6 py-4">
      <div>
        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('HELP_CENTER.CONTENT_GENERATION.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
          {{ $t('HELP_CENTER.CONTENT_GENERATION.DESCRIPTION') }}
        </p>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto px-6 py-6">
      <ContentGeneration 
        :portal-slug="portalSlug"
        @content-published="handleContentPublished"
      />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import ContentGeneration from './ContentGeneration.vue';

const route = useRoute();

// Computed properties
const portalSlug = computed(() => route.params.portalId);

// Methods
const handleContentPublished = () => {
  // Could show a success notification here
  console.log('Content has been published successfully');
};
</script>