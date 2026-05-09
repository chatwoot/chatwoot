<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import NotionAPI from 'dashboard/api/integrations/notion';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreateIssue from './CreateIssue.vue';
import NotionIssueItem from './NotionIssueItem.vue';
import NotionSetupCTA from './NotionSetupCTA.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  isConfigured: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const getters = useStoreGetters();

const linkedIssues = ref([]);
const isLoading = ref(false);
const shouldShowCreateModal = ref(false);

const conversation = computed(
  () => getters.getConversationById.value(props.conversationId) || {}
);

const createIssueTitle = computed(() => {
  const { meta: { sender: { name = null } = {} } = {} } = conversation.value;
  return t('INTEGRATION_SETTINGS.NOTION.CREATE.DEFAULT_TITLE', {
    conversationId: conversation.value.id || props.conversationId,
    name,
  });
});

const hasIssues = computed(() => linkedIssues.value.length > 0);

const errorMessage = (error, fallback) => {
  const parsedError = parseAPIErrorResponse(error);
  return typeof parsedError === 'string' ? parsedError : fallback;
};

const loadLinkedIssues = async () => {
  isLoading.value = true;
  linkedIssues.value = [];
  try {
    const response = await NotionAPI.getLinkedIssues(props.conversationId);
    linkedIssues.value = response.data || [];
  } catch (error) {
    useAlert(
      errorMessage(error, t('INTEGRATION_SETTINGS.NOTION.LOADING_ERROR'))
    );
  } finally {
    isLoading.value = false;
  }
};

const openCreateModal = () => {
  shouldShowCreateModal.value = true;
};

const closeCreateModal = () => {
  shouldShowCreateModal.value = false;
  loadLinkedIssues();
};

watch(
  () => props.conversationId,
  () => {
    loadLinkedIssues();
  }
);

onMounted(() => {
  loadLinkedIssues();
});
</script>

<template>
  <div>
    <div v-if="isConfigured" class="px-4 pt-3 pb-2">
      <NextButton
        ghost
        xs
        icon="i-lucide-plus"
        :label="$t('INTEGRATION_SETTINGS.NOTION.ADD_ISSUE_BUTTON')"
        @click="openCreateModal"
      />
    </div>

    <NotionSetupCTA v-else />

    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>

    <div v-else-if="!hasIssues" class="flex justify-center p-4">
      <p class="text-sm text-n-slate-11">
        {{ $t('INTEGRATION_SETTINGS.NOTION.NO_LINKED_ISSUES') }}
      </p>
    </div>

    <div v-else class="max-h-[300px] overflow-y-auto">
      <NotionIssueItem
        v-for="linkedIssue in linkedIssues"
        :key="linkedIssue.link_id || linkedIssue.id"
        class="px-4 pt-3 pb-4 border-b border-n-weak last:border-b-0"
        :issue="linkedIssue"
      />
    </div>

    <woot-modal
      v-model:show="shouldShowCreateModal"
      :on-close="closeCreateModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header
          :header-title="$t('INTEGRATION_SETTINGS.NOTION.CREATE.TITLE')"
          :header-content="$t('INTEGRATION_SETTINGS.NOTION.CREATE.DESCRIPTION')"
        />
        <div class="flex flex-col px-8 pb-6">
          <CreateIssue
            :conversation-id="conversationId"
            :title="createIssueTitle"
            @close="closeCreateModal"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
