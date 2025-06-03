<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import LinearIssueItem from './LinearIssueItem.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useTrack } from 'dashboard/composables';
import { LINEAR_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const getters = useStoreGetters();

const linkedIssues = ref([]);
const isLoading = ref(false);
const isUnlinking = ref(false);
const shouldShowCreateModal = ref(false);

const currentAccountId = getters.getCurrentAccountId;

const conversation = computed(
  () => getters.getConversationById.value(props.conversationId) || {}
);

const loadLinkedIssues = async () => {
  isLoading.value = true;
  linkedIssues.value = [];
  try {
    const response = await LinearAPI.getLinkedIssue(props.conversationId);
    const issues = response.data;
    linkedIssues.value = issues || [];
  } catch (error) {
    // We don't want to show an error message here, as it's not critical
  } finally {
    isLoading.value = false;
  }
};

const unlinkIssue = async linkId => {
  try {
    isUnlinking.value = true;
    await LinearAPI.unlinkIssue(linkId);
    useTrack(LINEAR_EVENTS.UNLINK_ISSUE);
    linkedIssues.value = linkedIssues.value.filter(
      issue => issue.id !== linkId
    );
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.UNLINK.SUCCESS'));
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.UNLINK.ERROR')
    );
    useAlert(errorMessage);
  } finally {
    isUnlinking.value = false;
  }
};

const hasIssues = computed(() => linkedIssues.value.length > 0);

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
  <div class="space-y-3">
    <!-- Create or link button -->
    <div class="p-3 border-b border-n-strong">
      <NextButton
        faded
        xs
        icon="i-lucide-plus"
        :label="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON')"
        @click="openCreateModal"
      />
    </div>

    <!-- Loading state -->
    <div v-if="isLoading" class="grid p-8 place-content-center">
      <Spinner />
    </div>

    <!-- Empty state -->
    <div v-else-if="!hasIssues" class="grid p-8 place-content-center">
      <p class="text-center">
        {{ t('INTEGRATION_SETTINGS.LINEAR.NO_LINKED_ISSUES') }}
      </p>
    </div>

    <!-- Issues list -->
    <div v-else class="max-h-[300px] overflow-scroll">
      <LinearIssueItem
        v-for="linkedIssue in linkedIssues"
        :key="linkedIssue.id"
        class="p-4 last-of-type:border-b-0"
        :linked-issue="linkedIssue"
        @unlink-issue="unlinkIssue"
      />
    </div>

    <woot-modal
      v-model:show="shouldShowCreateModal"
      :on-close="closeCreateModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <CreateOrLinkIssue
        :conversation="conversation"
        :account-id="currentAccountId"
        @close="closeCreateModal"
      />
    </woot-modal>
  </div>
</template>
