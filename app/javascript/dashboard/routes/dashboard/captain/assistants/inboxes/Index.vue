<script setup>
import { computed, onBeforeMount, onMounted, ref, nextTick } from 'vue';
import {
  useMapGetter,
  useStore,
  useStoreGetters,
} from 'dashboard/composables/store';
import { useRoute } from 'vue-router';

import BackButton from 'dashboard/components/widgets/BackButton.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConnectInboxDialog from 'dashboard/components-next/captain/pageComponents/inbox/ConnectInboxDialog.vue';
import InboxCard from 'dashboard/components-next/captain/assistant/InboxCard.vue';
import InboxPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/InboxPageEmptyState.vue';

const store = useStore();
const dialogType = ref('');
const route = useRoute();
const assistantUiFlags = useMapGetter('captainAssistants/getUIFlags');
const uiFlags = useMapGetter('captainInboxes/getUIFlags');
const isFetchingAssistant = computed(() => assistantUiFlags.value.fetchingItem);
const isFetching = computed(() => uiFlags.value.fetchingList);

const captainInboxes = useMapGetter('captainInboxes/getRecords');

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
  selectedInbox.value = captainInboxes.value.find(inbox => id === inbox.id);
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
const assistantId = Number(route.params.assistantId);
const assistant = computed(() =>
  getters['captainAssistants/getRecord'].value(assistantId)
);
onBeforeMount(() => store.dispatch('captainAssistants/show', assistantId));

onMounted(() =>
  store.dispatch('captainInboxes/get', {
    assistantId: assistantId,
  })
);
</script>

<template>
  <div
    v-if="isFetchingAssistant"
    class="flex items-center justify-center py-10 text-n-slate-11"
  >
    <Spinner />
  </div>
  <PageLayout
    v-else
    :button-label="$t('CAPTAIN.INBOXES.ADD_NEW')"
    :show-pagination-footer="false"
    @click="handleCreate"
  >
    <template #headerTitle>
      <div class="flex flex-row items-center gap-4">
        <BackButton compact />
        <span class="flex items-center gap-1 text-lg">
          {{ assistant.name }}
          <span class="i-lucide-chevron-right text-xl text-n-slate-10" />
          {{ $t('CAPTAIN.INBOXES.HEADER') }}
        </span>
      </div>
    </template>
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="captainInboxes.length" class="flex flex-col gap-4">
      <InboxCard
        v-for="captainInbox in captainInboxes"
        :id="captainInbox.id"
        :key="captainInbox.id"
        :inbox="captainInbox"
        @action="handleAction"
      />
    </div>

    <InboxPageEmptyState v-else @click="handleCreate" />

    <DeleteDialog
      v-if="selectedInbox"
      ref="disconnectInboxDialog"
      :entity="selectedInbox"
      :delete-payload="{
        assistantId: assistantId,
        inboxId: selectedInbox.id,
      }"
      type="Inboxes"
    />

    <ConnectInboxDialog
      v-if="dialogType"
      ref="connectInboxDialog"
      :assistant-id="assistantId"
      :type="dialogType"
      @close="handleCreateClose"
    />
  </PageLayout>
</template>
