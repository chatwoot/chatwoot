<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import AssistantForm from 'dashboard/components-next/captain/pageComponents/assistant/AssistantForm.vue';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const assistantId = route.params.assistantId;
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistant = computed(() =>
  store.getters['captainAssistants/getRecord'](Number(assistantId))
);

const isAssistantAvailable = computed(() => !!assistant.value?.id);

const handleSubmit = async updatedAssistant => {
  try {
    await store.dispatch('captainAssistants/update', {
      id: assistantId,
      ...updatedAssistant,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  if (!isAssistantAvailable.value) {
    store.dispatch('captainAssistants/show', assistantId);
  }
});
</script>

<template>
  <PageLayout
    :header-title="assistant?.name || $t('CAPTAIN.ASSISTANTS.EDIT')"
    :show-pagination-footer="false"
    :is-fetching="isFetching"
    :show-know-more="false"
  >
    <template #body>
      <AssistantForm
        v-if="isAssistantAvailable"
        :assistant="assistant"
        mode="edit"
        @submit="handleSubmit"
      />
    </template>
  </PageLayout>
</template>
