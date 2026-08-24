<script setup>
import { onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Draggable from 'vuedraggable';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import { useKanbanBoard } from './composables/useKanbanBoard';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const accountId = useMapGetter('getCurrentAccountId');
const labels = useMapGetter('labels/getLabelsOnSidebar');

const { columns, fetchBoard, moveCard } = useKanbanBoard();

onMounted(() => {
  store.dispatch('labels/get');
});

watch(
  labels,
  newLabels => {
    if (newLabels?.length) {
      fetchBoard(newLabels.map(label => label.title));
    }
  },
  { immediate: true }
);

const openConversation = conversation => {
  router.push(
    frontendURL(
      conversationUrl({ accountId: accountId.value, id: conversation.id })
    )
  );
};

const goToLabelSettings = () => {
  router.push(frontendURL(`accounts/${accountId.value}/labels`));
};

const onColumnChange = async (event, toLabel) => {
  const added = event?.added;
  if (!added) return;

  const conversation = added.element;
  const boardLabelTitles = labels.value.map(label => label.title);
  const fromLabel = (conversation.labels || []).find(
    label => label !== toLabel && boardLabelTitles.includes(label)
  );
  if (!fromLabel) return;

  try {
    await moveCard({ conversation, fromLabel, toLabel });
  } catch (error) {
    useAlert(t('KANBAN.MOVE_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden">
    <div
      class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
    >
      <h1 class="text-lg font-medium text-n-slate-12">
        {{ t('KANBAN.TITLE') }}
      </h1>
    </div>

    <div
      v-if="!labels.length"
      class="flex flex-col items-center justify-center flex-1 gap-2 text-center"
    >
      <p class="text-n-slate-12 font-medium">
        {{ t('KANBAN.NO_LABELS.TITLE') }}
      </p>
      <p class="text-n-slate-11 text-sm max-w-sm">
        {{ t('KANBAN.NO_LABELS.DESCRIPTION') }}
      </p>
      <NextButton size="sm" @click="goToLabelSettings">
        {{ t('KANBAN.NO_LABELS.BUTTON_TEXT') }}
      </NextButton>
    </div>

    <div v-else class="flex flex-1 gap-4 p-4 overflow-x-auto">
      <div
        v-for="label in labels"
        :key="label.id"
        class="flex flex-col flex-shrink-0 w-72 rounded-lg bg-n-solid-1 border border-n-weak"
      >
        <div class="flex items-center gap-2 px-3 py-2 border-b border-n-weak">
          <span
            class="size-[8px] rounded-sm flex-shrink-0"
            :style="{ backgroundColor: label.color }"
          />
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ label.title }}
          </span>
          <span class="ms-auto text-xs text-n-slate-11">
            {{ columns[label.title]?.conversations?.length ?? 0 }}
          </span>
        </div>

        <div class="flex-1 overflow-y-auto min-h-[120px]">
          <Spinner
            v-if="columns[label.title]?.isFetching"
            class="mx-auto my-4"
          />
          <Draggable
            v-else
            :list="columns[label.title]?.conversations ?? []"
            :group="{ name: 'kanban-conversations' }"
            item-key="id"
            animation="150"
            ghost-class="opacity-40"
            class="min-h-[120px]"
            @change="event => onColumnChange(event, label.title)"
          >
            <template #item="{ element: conversation }">
              <ConversationCard
                :chat="conversation"
                :current-contact="conversation.meta?.sender || {}"
                :assignee="conversation.meta?.assignee || {}"
                show-assignee
                compact
                @click="openConversation(conversation)"
              />
            </template>
          </Draggable>
          <p
            v-if="
              !columns[label.title]?.isFetching &&
              !columns[label.title]?.conversations?.length
            "
            class="px-3 py-4 text-xs text-center text-n-slate-11"
          >
            {{ t('KANBAN.EMPTY_COLUMN') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
