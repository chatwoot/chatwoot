<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import PageLayout from 'dashboard/components-next/aiagent/PageLayout.vue';
import EditAssistantForm from '../../../../components-next/aiagent/pageComponents/assistant/EditAssistantForm.vue';
import AssistantPlayground from 'dashboard/components-next/aiagent/assistant/AssistantPlayground.vue';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const assistantId = route.params.assistantId;
const uiFlags = useMapGetter('aiagentAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistant = computed(() =>
  store.getters['aiagentAssistants/getRecord'](Number(assistantId))
);

const isAssistantAvailable = computed(() => !!assistant.value?.id);

const handleSubmit = async updatedAssistant => {
  try {
    await store.dispatch('aiagentAssistants/update', {
      id: assistantId,
      ...updatedAssistant,
    });
    useAlert(t('AIAGENT.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('AIAGENT.ASSISTANTS.EDIT.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  if (!isAssistantAvailable.value) {
    store.dispatch('aiagentAssistants/show', assistantId);
  }
});
</script>

<template>
  <PageLayout
    :header-title="assistant?.name"
    :show-pagination-footer="false"
    :is-fetching="isFetching"
    :show-know-more="false"
    :back-url="{ name: 'aiagent_assistants_index' }"
  >
    <template #body>
      <div v-if="!isAssistantAvailable">
        {{ t('AIAGENT.ASSISTANTS.EDIT.NOT_FOUND') }}
      </div>
      <div v-else class="flex gap-4 h-full">
        <div class="flex-1 lg:overflow-auto pr-4 h-full md:h-auto">
          <EditAssistantForm
            :assistant="assistant"
            mode="edit"
            @submit="handleSubmit"
          />
        </div>
        <div class="w-[400px] hidden lg:block h-full">
          <AssistantPlayground :assistant-id="Number(assistantId)" />
        </div>
      </div>
    </template>
  </PageLayout>
</template>
