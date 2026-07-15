<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanColumn from './components/KanbanColumn.vue';

const store = useStore();
const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const boards = useMapGetter('kanban/getBoards');
const columns = useMapGetter('kanban/getColumns');
const cards = useMapGetter('kanban/getCards');
const conversations = useMapGetter('kanban/getConversations');
const uiFlags = useMapGetter('kanban/getUIFlags');
const currentRole = useMapGetter('getCurrentRole');

const selectedBoardId = ref(null);
const newBoardName = ref('');
const editBoardName = ref('');
const editingBoard = ref(null);
const newColumnName = ref('');
const newColumnColor = ref('blue');
const editColumnName = ref('');
const editColumnDescription = ref('');
const editColumnColor = ref('blue');
const editColumnWinProbability = ref('100');
const editingColumn = ref(null);
const selectedColumnForCard = ref(null);
const selectedConversationId = ref(null);
const conversationSearch = ref('');
const descriptionInputRef = ref(null);
const createBoardDialogRef = ref(null);
const editBoardDialogRef = ref(null);
const createColumnDialogRef = ref(null);
const editColumnDialogRef = ref(null);
const createCardDialogRef = ref(null);

const columnColorOptions = [
  {
    value: 'blue',
    label: 'Blue',
    hex: '#60a5fa',
    class: 'bg-n-blue-9',
    selectedClass: 'border-n-blue-8 bg-n-blue-3 text-n-blue-11 hover:bg-n-blue-4',
    hoverClass: 'hover:border-n-blue-8 hover:bg-n-blue-3 hover:text-n-blue-11',
  },
  {
    value: 'amber',
    label: 'Amber',
    hex: '#fbbf24',
    class: 'bg-n-amber-9',
    selectedClass: 'border-n-amber-8 bg-n-amber-3 text-n-amber-11 hover:bg-n-amber-4',
    hoverClass: 'hover:border-n-amber-8 hover:bg-n-amber-3 hover:text-n-amber-11',
  },
  {
    value: 'violet',
    label: 'Violet',
    hex: '#a78bfa',
    class: 'bg-n-violet-9',
    selectedClass: 'border-n-violet-8 bg-n-violet-3 text-n-violet-11 hover:bg-n-violet-4',
    hoverClass: 'hover:border-n-violet-8 hover:bg-n-violet-3 hover:text-n-violet-11',
  },
  {
    value: 'teal',
    label: 'Teal',
    hex: '#34d399',
    class: 'bg-n-teal-9',
    selectedClass: 'border-n-teal-8 bg-n-teal-3 text-n-teal-11 hover:bg-n-teal-4',
    hoverClass: 'hover:border-n-teal-8 hover:bg-n-teal-3 hover:text-n-teal-11',
  },
  {
    value: 'ruby',
    label: 'Ruby',
    hex: '#f87171',
    class: 'bg-n-ruby-9',
    selectedClass: 'border-n-ruby-8 bg-n-ruby-3 text-n-ruby-11 hover:bg-n-ruby-4',
    hoverClass: 'hover:border-n-ruby-8 hover:bg-n-ruby-3 hover:text-n-ruby-11',
  },
  {
    value: 'slate',
    label: 'Slate',
    hex: '#94a3b8',
    class: 'bg-n-slate-9',
    selectedClass: 'border-n-slate-8 bg-n-slate-3 text-n-slate-12 hover:bg-n-slate-4',
    hoverClass: 'hover:border-n-slate-8 hover:bg-n-slate-3 hover:text-n-slate-12',
  },
];

const DESCRIPTION_MAX_LENGTH = 120;
const DEFAULT_COLUMN_WIN_PROBABILITY = 100;

const selectedBoard = computed(() =>
  boards.value.find(board => board.id === Number(selectedBoardId.value))
);

const editColumnModalTitle = computed(() =>
  t('KANBAN.COLUMN.EDIT_MODAL_TITLE', {
    board: selectedBoard.value?.name || '',
  })
);

const selectedEditColumnColor = computed(() => {
  return (
    columnColorOptions.find(color => color.value === editColumnColor.value) ||
    columnColorOptions[0]
  );
});

const selectedConversation = computed(() =>
  conversations.value.find(
    conversation =>
      Number(conversation.id) === Number(selectedConversationId.value)
  )
);

const existingConversationIds = computed(
  () => new Set(cards.value.map(card => Number(card.conversationDisplayId)))
);

const conversationName = conversation => {
  return conversation.meta?.sender?.name || t('KANBAN.CARD.UNKNOWN_CONTACT');
};

const conversationPreview = conversation => {
  const lastMessage = conversation.messages?.[0] || conversation.lastNonActivityMessage;
  return lastMessage?.content || t('KANBAN.CARD.NO_PREVIEW');
};

const conversationInboxLabel = conversation => {
  return conversation.meta?.channel || conversation.status || '';
};

const availableConversations = computed(() => {
  const search = conversationSearch.value.trim().toLowerCase();

  return conversations.value
    .filter(conversation => !existingConversationIds.value.has(Number(conversation.id)))
    .filter(conversation => {
      if (!search) return true;

      return [
        conversation.id,
        conversationName(conversation),
        conversationPreview(conversation),
        conversationInboxLabel(conversation),
      ]
        .filter(Boolean)
        .some(value => String(value).toLowerCase().includes(search));
    });
});

const isOverview = computed(() => route.name === 'kanban_dashboard_index');

const boardRoute = boardId => ({
  name: 'kanban_board_show',
  params: {
    accountId: route.params.accountId,
    boardId,
  },
});

const canManageBoard = computed(() =>
  ['administrator', 'agent'].includes(currentRole.value)
);

const isLoadingBoard = computed(
  () => {
    if (isOverview.value) return uiFlags.value.isFetchingBoards;

    return (
      uiFlags.value.isFetchingBoards ||
      uiFlags.value.isFetchingColumns ||
      uiFlags.value.isFetchingCards
    );
  }
);

const orderedColumns = computed(() =>
  [...columns.value].sort((a, b) => a.position - b.position || a.id - b.id)
);

const cardsByColumn = columnId => {
  return cards.value
    .filter(card => card.kanbanColumnId === Number(columnId))
    .sort((a, b) => a.position - b.position || a.id - b.id);
};

const COLUMN_CHIP_TONES = {
  blue: 'bg-n-blue-3 text-n-blue-11',
  amber: 'bg-n-amber-3 text-n-amber-11',
  violet: 'bg-n-violet-3 text-n-violet-11',
  teal: 'bg-n-teal-3 text-n-teal-11',
  ruby: 'bg-n-ruby-3 text-n-ruby-11',
  slate: 'bg-n-slate-3 text-n-slate-11',
};

const normalizeColumnColor = color => {
  const normalizedColor = String(color || 'blue').toLowerCase();
  const colorAliases = {
    '#3b82f6': 'blue',
    '#60a5fa': 'blue',
    '#f59e0b': 'amber',
    '#fbbf24': 'amber',
    '#a78bfa': 'violet',
    '#8b5cf6': 'violet',
    purple: 'violet',
    '#10b981': 'teal',
    '#34d399': 'teal',
    green: 'teal',
    '#f87171': 'ruby',
    red: 'ruby',
    gray: 'slate',
    grey: 'slate',
  };

  return colorAliases[normalizedColor] || normalizedColor;
};

const columnChipClass = column => {
  const color = normalizeColumnColor(column.color);
  return COLUMN_CHIP_TONES[color] || COLUMN_CHIP_TONES.blue;
};

const loadBoard = async boardId => {
  if (!boardId) return;
  await Promise.all([
    store.dispatch('kanban/getColumns', boardId),
    store.dispatch('kanban/getCards', boardId),
  ]);
};

const openBoard = board => {
  router.push(boardRoute(board.id));
};

const openCreateBoardDialog = () => {
  createBoardDialogRef.value?.open();
};

const closeCreateBoardDialog = () => {
  newBoardName.value = '';
};

const openEditBoardDialog = board => {
  editingBoard.value = board;
  editBoardName.value = board.name || '';
  editBoardDialogRef.value?.open();
};

const closeEditBoardDialog = () => {
  editingBoard.value = null;
  editBoardName.value = '';
};

const openCreateColumnDialog = () => {
  createColumnDialogRef.value?.open();
};

const closeCreateColumnDialog = () => {
  newColumnName.value = '';
  newColumnColor.value = 'blue';
};

const parseProbability = value => {
  const parsedValue = Number(String(value || '').replace(',', '.'));
  if (!Number.isFinite(parsedValue)) return DEFAULT_COLUMN_WIN_PROBABILITY;

  return Math.min(100, Math.max(0, parsedValue));
};

const formatProbability = value => {
  return String(value ?? DEFAULT_COLUMN_WIN_PROBABILITY).replace('.', ',');
};

const openEditColumnDialog = column => {
  editingColumn.value = column;
  editColumnName.value = column.name || '';
  editColumnDescription.value = column.description || '';
  editColumnColor.value = normalizeColumnColor(column.color);
  editColumnWinProbability.value = formatProbability(column.winProbability);
  editColumnDialogRef.value?.open();
};

const closeEditColumnDialog = () => {
  editingColumn.value = null;
  editColumnName.value = '';
  editColumnDescription.value = '';
  editColumnColor.value = 'blue';
  editColumnWinProbability.value = '100';
};

const openCreateCardDialog = async column => {
  selectedColumnForCard.value = column;
  selectedConversationId.value = null;
  conversationSearch.value = '';
  createCardDialogRef.value?.open();

  try {
    await store.dispatch('kanban/getConversations');
  } catch (error) {
    useAlert(error?.message || t('KANBAN.CARD.CONVERSATIONS_ERROR'));
  }
};

const closeCreateCardDialog = () => {
  selectedColumnForCard.value = null;
  selectedConversationId.value = null;
  conversationSearch.value = '';
};

const copyEditingColumnId = () => {
  if (!editingColumn.value?.id) return;
  navigator.clipboard?.writeText(String(editingColumn.value.id));
  useAlert(t('KANBAN.COLUMN.ID_COPIED'));
};

const applyDescriptionFormat = (prefix, suffix = prefix) => {
  const input = descriptionInputRef.value;
  if (!input) return;

  const { selectionStart, selectionEnd } = input;
  const selectedText = editColumnDescription.value.slice(
    selectionStart,
    selectionEnd
  );
  const nextDescription = [
    editColumnDescription.value.slice(0, selectionStart),
    prefix,
    selectedText,
    suffix,
    editColumnDescription.value.slice(selectionEnd),
  ].join('');
  editColumnDescription.value = nextDescription.slice(0, DESCRIPTION_MAX_LENGTH);

  setTimeout(() => {
    input.focus();
    input.setSelectionRange(
      selectionStart + prefix.length,
      selectionEnd + prefix.length
    );
  });
};

const createBoard = async () => {
  const name = newBoardName.value.trim();
  if (!name) return;

  try {
    const board = await store.dispatch('kanban/createBoard', { name });
    createBoardDialogRef.value?.close();
    router.push(boardRoute(board.id));
    useAlert(t('KANBAN.BOARD.CREATE_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.BOARD.CREATE_ERROR'));
  }
};

const updateBoard = async () => {
  const name = editBoardName.value.trim();
  if (!name || !editingBoard.value) return;

  try {
    await store.dispatch('kanban/updateBoard', {
      id: editingBoard.value.id,
      name,
    });
    editBoardDialogRef.value?.close();
    useAlert(t('KANBAN.BOARD.EDIT_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.BOARD.EDIT_ERROR'));
  }
};

const createColumn = async () => {
  const name = newColumnName.value.trim();
  if (!name || !selectedBoardId.value) return;

  try {
    await store.dispatch('kanban/createColumn', {
      boardId: selectedBoardId.value,
      column: { name, color: newColumnColor.value },
    });
    store.dispatch('kanban/getBoards');
    createColumnDialogRef.value?.close();
    useAlert(t('KANBAN.COLUMN.CREATE_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.COLUMN.CREATE_ERROR'));
  }
};

const updateColumn = async () => {
  const name = editColumnName.value.trim();
  if (!name || !selectedBoardId.value || !editingColumn.value) return;

  try {
    await store.dispatch('kanban/updateColumn', {
      boardId: selectedBoardId.value,
      columnId: editingColumn.value.id,
      column: {
        name,
        description: editColumnDescription.value.trim(),
        color: editColumnColor.value,
        winProbability: parseProbability(editColumnWinProbability.value),
      },
    });
    store.dispatch('kanban/getBoards');
    editColumnDialogRef.value?.close();
    useAlert(t('KANBAN.COLUMN.EDIT_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.COLUMN.EDIT_ERROR'));
  }
};

const deleteBoard = async board => {
  const boardId = board?.id || selectedBoardId.value;
  if (
    !boardId ||
    !window.confirm(t('KANBAN.BOARD.DELETE_CONFIRM'))
  ) {
    return;
  }

  try {
    await store.dispatch('kanban/deleteBoard', boardId);
    if (!isOverview.value || Number(route.params.boardId) === Number(boardId)) {
      router.push({
        name: 'kanban_dashboard_index',
        params: { accountId: route.params.accountId },
      });
    }
    useAlert(t('KANBAN.BOARD.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.BOARD.DELETE_ERROR'));
  }
};

const deleteColumn = async column => {
  if (!window.confirm(t('KANBAN.COLUMN.DELETE_CONFIRM'))) return false;

  try {
    await store.dispatch('kanban/deleteColumn', {
      boardId: selectedBoardId.value,
      columnId: column.id,
    });
    store.dispatch('kanban/getBoards');
    useAlert(t('KANBAN.COLUMN.DELETE_SUCCESS'));
    return true;
  } catch (error) {
    useAlert(error?.message || t('KANBAN.COLUMN.DELETE_ERROR'));
    return false;
  }
};

const deleteEditingColumn = async () => {
  if (!editingColumn.value) return;
  const wasDeleted = await deleteColumn(editingColumn.value);
  if (wasDeleted) editColumnDialogRef.value?.close();
};

const createCard = async () => {
  if (!selectedColumnForCard.value || !selectedConversation.value) return;

  try {
    await store.dispatch('kanban/createCard', {
      boardId: selectedBoardId.value,
      card: {
        kanbanColumnId: selectedColumnForCard.value.id,
        conversationDisplayId: selectedConversation.value.id,
      },
    });
    store.dispatch('kanban/getBoards');
    createCardDialogRef.value?.close();
    useAlert(t('KANBAN.CARD.CREATE_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.CARD.CREATE_ERROR'));
  }
};

const deleteCard = async card => {
  try {
    await store.dispatch('kanban/deleteCard', {
      boardId: selectedBoardId.value,
      cardId: card.id,
    });
    store.dispatch('kanban/getBoards');
    useAlert(t('KANBAN.CARD.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('KANBAN.CARD.DELETE_ERROR'));
  }
};

const reorderColumn = payload => {
  store.dispatch('kanban/reorderColumn', payload);
};

const moveCard = async payload => {
  try {
    await store.dispatch('kanban/moveCard', {
      boardId: selectedBoardId.value,
      ...payload,
    });
    store.dispatch('kanban/getBoards');
  } catch (error) {
    useAlert(error?.message || t('KANBAN.CARD.MOVE_ERROR'));
  }
};

watch(
  () => route.params.boardId,
  boardId => {
    selectedBoardId.value = boardId ? Number(boardId) : null;
    if (boardId) loadBoard(boardId);
  }
);

watch(boards, currentBoards => {
  if (!route.params.boardId || !currentBoards.length) return;
  const hasBoard = currentBoards.some(
    board => board.id === Number(route.params.boardId)
  );
  if (!hasBoard) {
    router.push({
      name: 'kanban_dashboard_index',
      params: { accountId: route.params.accountId },
    });
  }
});

onMounted(async () => {
  await store.dispatch('kanban/getBoards');
  if (route.params.boardId) {
    selectedBoardId.value = Number(route.params.boardId);
    loadBoard(route.params.boardId);
  }
});
</script>

<template>
  <main
    class="flex h-full min-h-0 w-full flex-1 flex-col overflow-hidden bg-n-background"
  >
    <header
      v-if="isOverview"
      class="flex flex-col gap-4 border-b border-n-weak px-6 py-4 lg:flex-row lg:items-end lg:justify-between"
    >
      <div class="min-w-0">
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ $t('KANBAN.OVERVIEW.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-n-slate-11">
          {{ $t('KANBAN.OVERVIEW.DESCRIPTION') }}
        </p>
      </div>

      <div v-if="canManageBoard" class="flex items-center gap-2">
        <Button
          type="button"
          icon="i-lucide-layout-dashboard"
          sm
          :label="$t('KANBAN.BOARD.CREATE')"
          @click="openCreateBoardDialog"
        />
      </div>
    </header>

    <section
      v-if="isLoadingBoard"
      class="flex flex-1 items-center justify-center gap-3 text-n-slate-11"
    >
      <Spinner class="size-5" />
      <span class="text-sm">{{ $t('KANBAN.LOADING') }}</span>
    </section>

    <section
      v-else-if="isOverview && !boards.length"
      class="flex flex-1 items-center justify-center px-6"
    >
      <div
        class="w-full max-w-md rounded-md border border-n-weak p-6 text-center"
      >
        <h2 class="text-base font-medium text-n-slate-12">
          {{ $t('KANBAN.EMPTY_BOARD.TITLE') }}
        </h2>
        <p class="mt-2 text-sm text-n-slate-11">
          {{ $t('KANBAN.EMPTY_BOARD.DESCRIPTION') }}
        </p>
      </div>
    </section>

    <section
      v-else-if="isOverview"
      class="flex min-h-0 flex-1 flex-col gap-5 overflow-y-auto p-6"
    >
      <article
        v-for="board in boards"
        :key="board.id"
        class="w-full rounded-lg border border-n-weak bg-n-solid-2 p-5 transition-colors hover:bg-n-alpha-2"
      >
        <div class="flex items-start justify-between gap-4">
          <button
            type="button"
            class="min-w-0 flex-1 text-start"
            @click="openBoard(board)"
          >
            <div class="flex flex-wrap items-center gap-3">
              <h2 class="truncate text-lg font-semibold text-n-slate-12">
                {{ board.name }}
              </h2>
              <span
                class="grid h-7 min-w-7 place-items-center rounded-full bg-n-alpha-2 px-2 text-sm font-semibold text-n-slate-11"
              >
                {{ board.cardsCount || 0 }}
              </span>
            </div>
            <p v-if="board.description" class="mt-2 text-sm text-n-slate-11">
              {{ board.description }}
            </p>
          </button>

          <div v-if="canManageBoard" class="flex shrink-0 items-center gap-1">
            <Button
              v-tooltip.top="$t('KANBAN.BOARD.EDIT')"
              icon="i-lucide-pencil"
              slate
              ghost
              sm
              @click="openEditBoardDialog(board)"
            />
            <Button
              v-tooltip.top="$t('KANBAN.BOARD.DELETE')"
              icon="i-lucide-trash-2"
              ruby
              ghost
              sm
              @click="deleteBoard(board)"
            />
          </div>
        </div>

        <button
          type="button"
          class="mt-5 flex w-full flex-wrap gap-3 text-start"
          @click="openBoard(board)"
        >
          <span
            v-for="column in board.columns || []"
            :key="column.id"
            class="inline-flex items-center gap-2 rounded-md px-3 py-1 text-sm"
            :class="columnChipClass(column)"
          >
            <span class="size-2 rounded-full bg-current opacity-80" />
            <span>{{ column.name }}</span>
            <span
              class="grid size-5 place-items-center rounded-full bg-black/10 text-xs font-semibold"
            >
              {{ column.cardsCount || 0 }}
            </span>
          </span>
        </button>
      </article>
    </section>

    <section v-else class="flex min-h-0 flex-1 flex-col">
      <div
        class="flex flex-col gap-2 border-b border-n-weak bg-n-solid-1 px-5 py-2.5
          md:flex-row md:items-center"
      >
        <div class="min-w-0">
          <h2 class="truncate text-base font-semibold text-n-slate-12">
            {{ selectedBoard?.name }}
          </h2>
          <p class="text-xs text-n-slate-11">
            {{
              $t('KANBAN.BOARD.COUNTS', {
                columns: columns.length,
                cards: cards.length,
              })
            }}
          </p>
        </div>
      </div>

      <div
        v-if="orderedColumns.length || canManageBoard"
        class="flex flex-1 gap-3 overflow-x-auto p-4"
      >
        <KanbanColumn
          v-for="column in orderedColumns"
          :key="column.id"
          :column="column"
          :cards="cardsByColumn(column.id)"
          :is-creating-card="uiFlags.isCreatingCard"
          :can-manage="canManageBoard"
          @create-card="openCreateCardDialog"
          @delete-card="deleteCard"
          @delete-column="deleteColumn"
          @edit-column="openEditColumnDialog"
          @reorder="reorderColumn"
          @move-card="moveCard"
        />

        <button
          v-if="canManageBoard"
          type="button"
          class="flex min-h-[28rem] w-[19.5rem] shrink-0 items-center justify-center rounded-lg border border-dashed
            border-n-weak bg-n-background/60 p-4 text-n-blue-11 transition-colors hover:border-n-brand
            hover:bg-n-brand/10"
          @click="openCreateColumnDialog"
        >
          <span
            class="inline-flex items-center gap-2 rounded-md border border-n-brand px-4 py-2 text-sm font-medium"
          >
            <span class="i-lucide-plus size-4" />
            <span>{{ $t('KANBAN.COLUMN.CREATE') }}</span>
          </span>
        </button>
      </div>

      <div v-else class="flex flex-1 items-center justify-center px-6">
        <div
          class="w-full max-w-md rounded-md border border-n-weak p-6 text-center"
        >
          <h2 class="text-base font-medium text-n-slate-12">
            {{ $t('KANBAN.EMPTY_COLUMN.TITLE') }}
          </h2>
          <p class="mt-2 text-sm text-n-slate-11">
            {{ $t('KANBAN.EMPTY_COLUMN.DESCRIPTION') }}
          </p>
        </div>
      </div>
    </section>

    <Dialog
      ref="createBoardDialogRef"
      :title="$t('KANBAN.BOARD.MODAL_TITLE')"
      :description="$t('KANBAN.BOARD.MODAL_DESCRIPTION')"
      :confirm-button-label="$t('KANBAN.BOARD.CREATE')"
      :disable-confirm-button="!newBoardName.trim()"
      :is-loading="uiFlags.isCreatingBoard"
      width="md"
      @confirm="createBoard"
      @close="closeCreateBoardDialog"
    >
      <label class="mb-2 block text-sm font-medium text-n-slate-12">
        {{ $t('KANBAN.BOARD.NAME_LABEL') }}
      </label>
      <input
        v-model="newBoardName"
        type="text"
        class="h-10 w-full rounded-md border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
        :placeholder="$t('KANBAN.BOARD.NAME_PLACEHOLDER')"
      />
    </Dialog>

    <Dialog
      ref="editBoardDialogRef"
      :title="$t('KANBAN.BOARD.EDIT_MODAL_TITLE')"
      :description="$t('KANBAN.BOARD.EDIT_MODAL_DESCRIPTION')"
      :confirm-button-label="$t('KANBAN.BOARD.UPDATE')"
      :disable-confirm-button="!editBoardName.trim()"
      :is-loading="uiFlags.isUpdatingBoard"
      width="md"
      @confirm="updateBoard"
      @close="closeEditBoardDialog"
    >
      <label class="mb-2 block text-sm font-medium text-n-slate-12">
        {{ $t('KANBAN.BOARD.NAME_LABEL') }}
      </label>
      <input
        v-model="editBoardName"
        type="text"
        class="h-10 w-full rounded-md border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
        :placeholder="$t('KANBAN.BOARD.NAME_PLACEHOLDER')"
      />
    </Dialog>

    <Dialog
      ref="editColumnDialogRef"
      width="2xl"
      overflow-y-auto
      :show-cancel-button="false"
      :show-confirm-button="false"
      @confirm="updateColumn"
      @close="closeEditColumnDialog"
    >
      <div class="flex items-start justify-between gap-4">
        <h3 class="text-2xl font-semibold text-n-slate-12">
          {{ editColumnModalTitle }}
        </h3>
        <div class="flex shrink-0 items-center gap-2 text-n-slate-11">
          <span class="text-sm font-medium">
            {{ $t('KANBAN.COLUMN.ID_LABEL', { id: editingColumn?.id }) }}
          </span>
          <Button
            v-tooltip.top="$t('KANBAN.COLUMN.COPY_ID')"
            type="button"
            icon="i-lucide-copy"
            slate
            faded
            sm
            @click="copyEditingColumnId"
          />
        </div>
      </div>

      <div class="grid gap-5">
        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.NAME_LABEL') }}
          </label>
          <input
            v-model="editColumnName"
            type="text"
            class="h-12 w-full rounded-md border border-n-weak bg-n-alpha-1 px-4 text-base text-n-slate-12 outline-none
              focus:border-n-brand"
            :placeholder="$t('KANBAN.COLUMN.NAME_PLACEHOLDER')"
          />
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.DESCRIPTION_LABEL') }}
          </label>
          <div
            class="overflow-hidden rounded-md border border-n-weak bg-n-alpha-1"
          >
            <div class="flex flex-wrap items-center gap-1 border-b border-n-weak p-3">
              <Button
                type="button"
                icon="i-lucide-bold"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('**')"
              />
              <Button
                type="button"
                icon="i-lucide-italic"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('_')"
              />
              <Button
                type="button"
                icon="i-lucide-code"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('`')"
              />
              <Button
                type="button"
                icon="i-lucide-link"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('[', '](url)')"
              />
              <Button
                type="button"
                icon="i-lucide-strikethrough"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('~~')"
              />
              <Button
                type="button"
                icon="i-lucide-list"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('- ', '')"
              />
              <Button
                type="button"
                icon="i-lucide-list-ordered"
                slate
                ghost
                sm
                @click="applyDescriptionFormat('1. ', '')"
              />
              <Button
                type="button"
                icon="i-lucide-undo-2"
                slate
                ghost
                sm
                disabled
              />
              <Button
                type="button"
                icon="i-lucide-redo-2"
                slate
                ghost
                sm
                disabled
              />
            </div>
            <div class="relative">
              <textarea
                ref="descriptionInputRef"
                v-model="editColumnDescription"
                class="h-40 w-full resize-none bg-transparent px-4 py-3 text-base text-n-slate-12 outline-none
                  placeholder:text-n-slate-10"
                :maxlength="DESCRIPTION_MAX_LENGTH"
                :placeholder="$t('KANBAN.COLUMN.DESCRIPTION_PLACEHOLDER')"
              />
              <span
                class="absolute bottom-3 right-4 text-sm text-n-slate-10"
              >
                {{ editColumnDescription.length }} / {{ DESCRIPTION_MAX_LENGTH }}
              </span>
            </div>
          </div>
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.COLOR_LABEL') }}
          </label>
          <div class="flex flex-wrap items-center gap-2">
            <div
              class="flex h-11 items-center gap-3 rounded-md bg-n-alpha-2 px-4 text-base font-medium text-n-slate-12"
            >
              <span
                class="size-5 rounded-md"
                :class="selectedEditColumnColor.class"
              />
              <span>{{ selectedEditColumnColor.hex }}</span>
              <span class="i-lucide-pipette size-4 text-n-slate-11" />
            </div>
            <button
              v-for="color in columnColorOptions"
              :key="color.value"
              type="button"
              class="grid size-9 place-items-center rounded-md border border-n-weak transition-colors
                text-n-slate-12"
              :class="
                editColumnColor === color.value
                  ? color.selectedClass
                  : color.hoverClass
              "
              @click="editColumnColor = color.value"
            >
              <span class="size-5 rounded-full" :class="color.class" />
            </button>
          </div>
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.WIN_PROBABILITY_LABEL') }}
          </label>
          <div class="flex items-center gap-3">
            <input
              v-model="editColumnWinProbability"
              type="text"
              inputmode="decimal"
              class="h-11 min-w-0 flex-1 rounded-md border border-n-weak bg-n-alpha-1 px-4 text-base text-n-slate-12
                outline-none focus:border-n-brand"
            />
            <span class="text-base font-semibold text-n-slate-11">%</span>
          </div>
          <p class="mt-2 text-sm text-n-slate-11">
            {{ $t('KANBAN.COLUMN.WIN_PROBABILITY_HELP') }}
          </p>
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-between gap-4">
          <Button
            type="button"
            ruby
            link
            :label="$t('KANBAN.COLUMN.DELETE')"
            @click="deleteEditingColumn"
          />
          <div class="flex items-center gap-3">
            <Button
              type="button"
              slate
              link
              :label="$t('DIALOG.BUTTONS.CANCEL')"
              @click="editColumnDialogRef.close()"
            />
            <Button
              type="submit"
              :label="$t('KANBAN.COLUMN.UPDATE')"
              :is-loading="uiFlags.isUpdatingColumn"
              :disabled="!editColumnName.trim() || uiFlags.isUpdatingColumn"
            />
          </div>
        </div>
      </template>
    </Dialog>

    <Dialog
      ref="createCardDialogRef"
      :title="$t('KANBAN.CARD.MODAL_TITLE')"
      :description="
        $t('KANBAN.CARD.MODAL_DESCRIPTION', {
          column: selectedColumnForCard?.name || '',
        })
      "
      :confirm-button-label="$t('KANBAN.CARD.CREATE')"
      :disable-confirm-button="!selectedConversation"
      :is-loading="uiFlags.isCreatingCard"
      width="2xl"
      overflow-y-auto
      @confirm="createCard"
      @close="closeCreateCardDialog"
    >
      <div class="grid gap-4">
        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.CARD.SEARCH_LABEL') }}
          </label>
          <div class="relative">
            <span
              class="i-lucide-search absolute left-3 top-1/2 size-4 -translate-y-1/2 text-n-slate-10"
            />
            <input
              v-model="conversationSearch"
              type="text"
              class="h-10 w-full rounded-md border border-n-weak bg-n-alpha-1 pl-9 pr-3 text-sm text-n-slate-12
                outline-none focus:border-n-brand"
              :placeholder="$t('KANBAN.CARD.SEARCH_PLACEHOLDER')"
            />
          </div>
        </div>

        <div
          v-if="uiFlags.isFetchingConversations"
          class="flex items-center justify-center gap-3 rounded-md border border-n-weak p-6 text-sm text-n-slate-11"
        >
          <Spinner class="size-4" />
          <span>{{ $t('KANBAN.CARD.LOADING_CONVERSATIONS') }}</span>
        </div>

        <div
          v-else-if="!availableConversations.length"
          class="rounded-md border border-n-weak p-6 text-center text-sm text-n-slate-11"
        >
          {{ $t('KANBAN.CARD.EMPTY_CONVERSATIONS') }}
        </div>

        <div v-else class="grid max-h-[24rem] gap-2 overflow-y-auto pr-1">
          <button
            v-for="conversation in availableConversations"
            :key="conversation.id"
            type="button"
            class="flex min-w-0 items-start gap-3 rounded-md border border-n-weak bg-n-alpha-1 p-3 text-start
              transition-colors hover:bg-n-alpha-2"
            :class="{
              'border-n-brand bg-n-brand/10':
                Number(selectedConversationId) === Number(conversation.id),
            }"
            @click="selectedConversationId = Number(conversation.id)"
          >
            <span
              class="grid size-10 shrink-0 place-items-center rounded-full bg-n-alpha-2 text-sm font-semibold
                text-n-slate-12"
            >
              {{ conversationName(conversation).slice(0, 1).toUpperCase() }}
            </span>
            <span class="min-w-0 flex-1">
              <span class="flex min-w-0 items-center gap-2">
                <span class="truncate text-sm font-semibold text-n-slate-12">
                  #{{ conversation.id }} - {{ conversationName(conversation) }}
                </span>
                <span
                  class="shrink-0 rounded-sm bg-n-slate-3 px-2 py-0.5 text-xs text-n-slate-11"
                >
                  {{ conversation.status }}
                </span>
              </span>
              <span class="mt-1 line-clamp-2 text-sm text-n-slate-11">
                {{ conversationPreview(conversation) }}
              </span>
              <span
                v-if="conversationInboxLabel(conversation)"
                class="mt-2 inline-flex items-center gap-1 text-xs text-n-slate-10"
              >
                <span class="i-lucide-inbox size-3" />
                <span>{{ conversationInboxLabel(conversation) }}</span>
              </span>
            </span>
            <span
              class="grid size-5 shrink-0 place-items-center rounded-full border border-n-weak"
              :class="{
                'border-n-brand bg-n-brand text-white':
                  Number(selectedConversationId) === Number(conversation.id),
              }"
            >
              <span
                v-if="Number(selectedConversationId) === Number(conversation.id)"
                class="i-lucide-check size-3"
              />
            </span>
          </button>
        </div>
      </div>
    </Dialog>

    <Dialog
      ref="createColumnDialogRef"
      :title="$t('KANBAN.COLUMN.MODAL_TITLE')"
      :description="$t('KANBAN.COLUMN.MODAL_DESCRIPTION')"
      :confirm-button-label="$t('KANBAN.COLUMN.CREATE')"
      :disable-confirm-button="!newColumnName.trim()"
      :is-loading="uiFlags.isCreatingColumn"
      width="md"
      @confirm="createColumn"
      @close="closeCreateColumnDialog"
    >
      <div class="grid gap-4">
        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.NAME_LABEL') }}
          </label>
          <input
            v-model="newColumnName"
            type="text"
            class="h-10 w-full rounded-md border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
            :placeholder="$t('KANBAN.COLUMN.NAME_PLACEHOLDER')"
          />
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-n-slate-12">
            {{ $t('KANBAN.COLUMN.COLOR_LABEL') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in columnColorOptions"
              :key="color.value"
              type="button"
              class="flex h-9 items-center gap-2 rounded-md border border-n-weak px-3 text-sm transition-colors"
              :class="
                newColumnColor === color.value
                  ? color.selectedClass
                  : color.hoverClass
              "
              @click="newColumnColor = color.value"
            >
              <span class="size-4 rounded-full" :class="color.class" />
              <span>{{ color.label }}</span>
            </button>
          </div>
        </div>
      </div>
    </Dialog>
  </main>
</template>
