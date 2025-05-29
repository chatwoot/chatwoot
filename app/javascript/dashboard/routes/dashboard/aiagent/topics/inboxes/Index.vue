<script setup>
import { computed, onBeforeMount, onMounted, ref, nextTick } from 'vue';
import {
  useMapGetter,
  useStore,
  useStoreGetters,
} from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import BackButton from 'dashboard/components/widgets/BackButton.vue';
import DeleteDialog from 'dashboard/components-next/aiagent/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/aiagent/PageLayout.vue';
import ConnectInboxDialog from 'dashboard/components-next/aiagent/pageComponents/inbox/ConnectInboxDialog.vue';
import InboxCard from 'dashboard/components-next/aiagent/topic/InboxCard.vue';
import InboxPageEmptyState from 'dashboard/components-next/aiagent/pageComponents/emptyStates/InboxPageEmptyState.vue';

const store = useStore();
const dialogType = ref('');
const route = useRoute();
const topicUiFlags = useMapGetter('aiagentTopics/getUIFlags');
const uiFlags = useMapGetter('aiagentInboxes/getUIFlags');
const isFetchingTopic = computed(() => topicUiFlags.value.fetchingItem);
const isFetching = computed(() => uiFlags.value.fetchingList);

const aiagentInboxes = useMapGetter('aiagentInboxes/getRecords');

const selectedInbox = ref(null);
const disconnectInboxDialog = ref(null);

const handleDelete = () => {
  disconnectInboxDialog.value.dialogRef.open();
};

const connectInboxDialog = ref(null);

const handleCreate = () => {
  dialogType.value = 'create';
  nextTick(() => connectInboxDialog.value.dialogRef.open());
};
const handleAction = ({ action, id }) => {
  selectedInbox.value = aiagentInboxes.value.find(inbox => id === inbox.id);
  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    }
  });
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedInbox.value = null;
};

const getters = useStoreGetters();
const topicId = Number(route.params.topicId);
const topic = computed(() => getters['aiagentTopics/getRecord'].value(topicId));
onBeforeMount(() => store.dispatch('aiagentTopics/show', topicId));

onMounted(() =>
  store.dispatch('aiagentInboxes/get', {
    topicId: topicId,
  })
);
</script>

<template>
  <PageLayout
    :button-label="$t('AIAGENT.INBOXES.ADD_NEW')"
    :button-policy="['administrator']"
    :is-fetching="isFetchingTopic || isFetching"
    :is-empty="!aiagentInboxes.length"
    :show-pagination-footer="false"
    :feature-flag="FEATURE_FLAGS.AIAGENT"
    @click="handleCreate"
  >
    <template v-if="!isFetchingTopic" #headerTitle>
      <div class="flex flex-row items-center gap-4">
        <BackButton compact />
        <span
          class="flex items-center gap-1 text-lg font-medium text-n-slate-12"
        >
          {{ topic.name }}
          <span class="i-lucide-chevron-right text-xl text-n-slate-10" />
          {{ $t('AIAGENT.INBOXES.HEADER') }}
        </span>
      </div>
    </template>

    <template #emptyState>
      <InboxPageEmptyState @click="handleCreate" />
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <InboxCard
          v-for="aiagentInbox in aiagentInboxes"
          :id="aiagentInbox.id"
          :key="aiagentInbox.id"
          :inbox="aiagentInbox"
          @action="handleAction"
        />
      </div>
    </template>

    <DeleteDialog
      v-if="selectedInbox"
      ref="disconnectInboxDialog"
      :entity="selectedInbox"
      :delete-payload="{
        topicId: topicId,
        inboxId: selectedInbox.id,
      }"
      type="Inboxes"
    />

    <ConnectInboxDialog
      v-if="dialogType"
      ref="connectInboxDialog"
      :topic-id="topicId"
      :type="dialogType"
      @close="handleCreateClose"
    />
  </PageLayout>
</template>
