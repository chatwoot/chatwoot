<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import PromptEditor from './PromptEditor.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const isUpdating = ref(false);
const isSaved = ref(false);
const isLoading = ref(true);

const getPromptById = useMapGetter('prompts/getPromptById');

const promptId = computed(() => route.params.id);

const prompt = computed(() => {
  // Use dynamic data from store with proper type conversion
  const foundPrompt = getPromptById.value(promptId.value);
  return foundPrompt || {};
});

const fetchPrompt = async () => {
  isLoading.value = true;
  try {
    // Always fetch fresh data from the API
    await store.dispatch('prompts/get');
  } catch (error) {
    // Handle error silently for now
  } finally {
    isLoading.value = false;
  }
};

const updatePrompt = async promptData => {
  isUpdating.value = true;
  try {
    await store.dispatch('prompts/update', {
      id: promptId.value,
      ...promptData,
    });
    useAlert(t('PROMPTS_PAGE.EDIT.SUCCESS_MESSAGE'));

    // Refresh the prompts data to ensure we have the latest changes
    await store.dispatch('prompts/get');

    router.push({ name: 'prompts_list' });
  } catch (error) {
    useAlert(t('PROMPTS_PAGE.EDIT.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'prompts_list' });
};

onMounted(() => {
  fetchPrompt();
});
</script>

<template>
  <PromptEditor
    v-if="!isLoading && (prompt.id || prompt.prompt_key)"
    :prompt="prompt"
    :is-updating="isUpdating"
    :is-saved="isSaved"
    :is-readonly="false"
    @save-prompt="updatePrompt"
    @go-back="goBack"
  />
  <div v-else class="flex justify-center py-8">
    <div class="text-slate-600 dark:text-slate-400">
      {{ t('PROMPTS_PAGE.LOADING') }}
    </div>
  </div>
</template>
