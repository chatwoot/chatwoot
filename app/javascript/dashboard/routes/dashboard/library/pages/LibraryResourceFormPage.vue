<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import { useLibraryResources } from '../composables/useLibraryResources';
import LibraryResourceForm from '../components/LibraryResourceForm.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';

const route = useRoute();
const router = useRouter();
useI18n();

const { getResourceById, addResource, updateResource, fetchResource } =
  useLibraryResources();

const resource = ref(null);
const isLoading = ref(false);
const isEdit = ref(false);

onMounted(async () => {
  const resourceId = route.params.id;
  if (resourceId) {
    isEdit.value = true;

    // Try to get from store first
    resource.value = getResourceById(parseInt(resourceId, 10));

    // If not in store, fetch from API
    if (!resource.value) {
      try {
        resource.value = await fetchResource(parseInt(resourceId, 10));
      } catch (error) {
        // Redirect to library if resource not found
        router.push({ name: 'library_index' });
      }
    }
  }
});

const handleSave = async formData => {
  isLoading.value = true;

  try {
    if (isEdit.value && resource.value) {
      // Update existing resource
      updateResource(resource.value.id, formData);
    } else {
      // Add new resource
      addResource(formData);
    }

    // Redirect back to library
    router.push({ name: 'library_index' });
  } finally {
    isLoading.value = false;
  }
};

const handleCancel = () => {
  router.push({ name: 'library_index' });
};
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <div class="flex flex-col items-center px-6 py-8">
      <div class="w-full max-w-3xl">
        <CardLayout>
          <LibraryResourceForm
            :resource="resource"
            :is-loading="isLoading"
            @save="handleSave"
            @cancel="handleCancel"
          />
        </CardLayout>
      </div>
    </div>
  </div>
</template>
