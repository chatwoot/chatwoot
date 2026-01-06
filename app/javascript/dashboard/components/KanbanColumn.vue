<script setup>
import { computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useStore } from 'vuex';
import Draggable from 'vuedraggable';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';
import IntersectionObserver from './IntersectionObserver.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: { type: String, required: true },
  title: { type: String, required: true },
  conversations: { type: Array, default: () => [] },
  count: { type: Number, default: 0 },
  hasMore: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
});

const emit = defineEmits(['change', 'loadMore']);
const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const accountLabels = computed(() => store.getters['labels/getLabels']);

function getInbox(inboxId) {
  return store.getters['inboxes/getInbox'](inboxId) || {};
}

const localList = computed({
  get: () => props.conversations,
  set: () => {},
});

function onDragChange(evt) {
  if (evt.added) {
    emit('change', {
      conversation: evt.added.element,
      toStatus: props.status,
    });
  }
}

function onCardClick(conversation) {
  router.push(
    `/app/accounts/${route.params.accountId}/conversations/${conversation.id}`
  );
}

function onLoadMore() {
  if (!props.loading && props.hasMore) {
    emit('loadMore');
  }
}
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 overflow-hidden w-72 bg-n-solid-2 rounded-xl"
  >
    <!-- Header -->
    <div
      class="flex items-center justify-between px-3 py-2 border-b border-n-weak"
    >
      <h3 class="text-sm font-semibold text-n-slate-12">{{ title }}</h3>
      <span
        class="px-2 py-0.5 text-xs font-medium rounded-md bg-n-alpha-2 text-n-slate-11"
      >
        {{ count }}
      </span>
    </div>

    <!-- Draggable List -->
    <Draggable
      v-model="localList"
      group="kanban"
      item-key="id"
      animation="200"
      ghost-class="opacity-50"
      class="flex-1 p-2 space-y-2 overflow-y-auto min-h-[200px]"
      @change="onDragChange"
    >
      <template #item="{ element }">
        <div
          class="transition-shadow rounded-xl bg-n-solid-1 shadow-sm cursor-grab active:cursor-grabbing hover:shadow-md"
          @click="onCardClick(element)"
        >
          <ConversationCard
            :conversation="element"
            :contact="element.meta?.sender || {}"
            :state-inbox="getInbox(element.inbox_id)"
            :account-labels="accountLabels"
          />
        </div>
      </template>
    </Draggable>

    <!-- Empty State -->
    <div
      v-if="!conversations.length && !loading"
      class="flex items-center justify-center flex-1 p-4 text-sm text-n-slate-10"
    >
      {{ t('CHAT_LIST.KANBAN.NO_CONVERSATIONS') }}
    </div>

    <!-- Load More -->
    <div v-if="hasMore" class="p-2 border-t border-n-weak">
      <Spinner v-if="loading" class="mx-auto size-4" />
      <IntersectionObserver v-else @observed="onLoadMore" />
    </div>
  </div>
</template>
