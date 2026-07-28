<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import SettingsNav from './SettingsNav.vue';

defineProps({
  heading: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
</script>

<template>
  <PageLayout
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <div class="flex gap-8 pb-8">
        <SettingsNav />
        <div class="flex flex-col flex-1 min-w-0 gap-6">
          <SettingsHeader :heading="heading" :description="description" />
          <slot />
        </div>
      </div>
    </template>
  </PageLayout>
</template>
