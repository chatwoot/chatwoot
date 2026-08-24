<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Draggable from 'vuedraggable';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import {
  useKanbanBoard,
  UNASSIGNED_COLUMN_KEY,
} from './composables/useKanbanBoard';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const accountId = useMapGetter('getCurrentAccountId');
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);

// Only "List" type conversation attributes can drive the board — their
// pre-defined values become the columns.
const listAttributes = computed(() =>
  conversationAttributes.value.filter(
    attribute => attribute.attributeDisplayType === 'list'
  )
);

const selectedAttributeKey = ref('');

watch(
  listAttributes,
  newAttributes => {
    const stillExists = newAttributes.some(
      attribute => attribute.attributeKey === selectedAttributeKey.value
    );
    if (!stillExists) {
      selectedAttributeKey.value = newAttributes[0]?.attributeKey ?? '';
    }
  },
  { immediate: true }
);

const selectedAttribute = computed(() =>
  listAttributes.value.find(
    attribute => attribute.attributeKey === selectedAttributeKey.value
  )
);

const columnValues = computed(() => [
  ...(selectedAttribute.value?.attributeValues ?? []),
  UNASSIGNED_COLUMN_KEY,
]);

const columnLabel = value =>
  value === UNASSIGNED_COLUMN_KEY ? t('KANBAN.UNASSIGNED_COLUMN') : value;

const { columns, fetchBoard, moveCard } = useKanbanBoard();

onMounted(() => {
  store.dispatch('attributes/get');
});

watch(
  [selectedAttributeKey, columnValues],
  () => {
    if (selectedAttributeKey.value) {
      fetchBoard(selectedAttributeKey.value, columnValues.value);
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

const goToAttributeSettings = () => {
  router.push({
    name: 'attributes_list',
    params: { accountId: accountId.value },
  });
};

const onColumnChange = async (event, toValue) => {
  const added = event?.added;
  if (!added) return;

  const conversation = added.element;
  const fromValue =
    conversation.custom_attributes?.[selectedAttributeKey.value] ??
    UNASSIGNED_COLUMN_KEY;

  try {
    await moveCard({
      conversation,
      attributeKey: selectedAttributeKey.value,
      fromValue,
      toValue,
    });
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
      <select
        v-if="listAttributes.length > 1"
        v-model="selectedAttributeKey"
        class="reset-base !w-auto !mb-0 text-sm"
      >
        <option
          v-for="attribute in listAttributes"
          :key="attribute.attributeKey"
          :value="attribute.attributeKey"
        >
          {{ attribute.attributeDisplayName }}
        </option>
      </select>
    </div>

    <div
      v-if="!selectedAttribute"
      class="flex flex-col items-center justify-center flex-1 gap-2 text-center"
    >
      <p class="text-n-slate-12 font-medium">
        {{ t('KANBAN.NO_ATTRIBUTE.TITLE') }}
      </p>
      <p class="text-n-slate-11 text-sm max-w-sm">
        {{ t('KANBAN.NO_ATTRIBUTE.DESCRIPTION') }}
      </p>
      <NextButton size="sm" @click="goToAttributeSettings">
        {{ t('KANBAN.NO_ATTRIBUTE.BUTTON_TEXT') }}
      </NextButton>
    </div>

    <div v-else class="flex flex-1 gap-4 p-4 overflow-x-auto">
      <div
        v-for="value in columnValues"
        :key="value"
        class="flex flex-col flex-shrink-0 w-72 rounded-lg bg-n-solid-1 border border-n-weak"
      >
        <div class="flex items-center gap-2 px-3 py-2 border-b border-n-weak">
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ columnLabel(value) }}
          </span>
          <span class="ms-auto text-xs text-n-slate-11">
            {{ columns[value]?.conversations?.length ?? 0 }}
          </span>
        </div>

        <div class="flex-1 overflow-y-auto min-h-[120px]">
          <Spinner v-if="columns[value]?.isFetching" class="mx-auto my-4" />
          <Draggable
            v-else
            :list="columns[value]?.conversations ?? []"
            :group="{ name: 'kanban-conversations' }"
            item-key="id"
            animation="150"
            ghost-class="opacity-40"
            class="min-h-[120px]"
            @change="event => onColumnChange(event, value)"
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
              !columns[value]?.isFetching &&
              !columns[value]?.conversations?.length
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
