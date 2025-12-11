<script setup>
import draggable from 'vuedraggable';
import ConversationCard from './ConversationCard.vue';
import { ref, nextTick, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from '../../../../components-next/button/Button.vue';

const props = defineProps({
  column: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['deleted']);
const store = useStore();
const { t } = useI18n();

// =================== Initializing =================== //

const isEditing = ref(props.column.is_new);
const newName = ref(props.column.name);
const inputRef = ref(null);
const showDeleteModal = ref(false);

const localConversations = computed({
  get: () => props.column.conversations || [],
  set: () => {},
});

const saveName = async () => {
  if (props.column.is_new && newName.value.trim() === '') {
    isEditing.value = false;
    emit('deleted', props.column);
    return;
  }

  if (newName.value.trim() === '' || newName.value === props.column.name) {
    isEditing.value = false;
    return;
  }

  if (props.column.id) {
    await store.dispatch('pipelineStatuses/update', {
      id: props.column.id,
      name: newName.value,
    });
  } else {
    emit('deleted', props.column);

    await store.dispatch('pipelineStatuses/create', {
      name: newName.value,
    });
  }

  isEditing.value = false;
};

const openDeleteModal = () => {
  if (localConversations.value.length > 0) {
    useAlert(t('PIPELINE_STATUS.DELETE_WITH_CONVERSATIONS'));
    return;
  }

  showDeleteModal.value = true;
};

const confirmDeletion = async () => {
  try {
    await store.dispatch('pipelineStatuses/delete', props.column.id);
    useAlert(t('PIPELINE_STATUS.DELETE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE_STATUS.DELETE_FAILED'));
  }

  showDeleteModal.value = false;
};

const closeDeleteModal = () => {
  showDeleteModal.value = false;
};

const startEditing = async () => {
  isEditing.value = true;
  newName.value = props.column.name;

  await nextTick();

  inputRef.value?.select();
};

const onDragEnd = async event => {
  if (!store.getters.getListLoadingStatusPipelineFlag) {
    const toColumnId = event.to.parentElement.parentElement.dataset.columnId;
    const conversationId = event.item.dataset.conversationId;

    store.dispatch('togglePipelineStatus', {
      pipelineStatusId: toColumnId,
      conversationId: conversationId,
    });
  }
};
</script>

<template>
  <div class="flex flex-col flex-shrink-0 w-72" :data-column-id="column.id">
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :on-close="closeDeleteModal"
      :on-confirm="confirmDeletion"
      :title="$t('PIPELINE_STATUS.DELETE_CONFIRMATION.TITLE')"
      :message="$t('PIPELINE_STATUS.DELETE_CONFIRMATION.MESSAGE')"
      :confirm-text="$t('PIPELINE_STATUS.DELETE_CONFIRMATION.DELETE')"
      :reject-text="$t('PIPELINE_STATUS.DELETE_CONFIRMATION.CANCEL')"
    />
    <div
      class="flex items-center justify-between flex-shrink-0 h-10 px-2 bg-n-solid-3 outline outline-n-container outline-1 -outline-offset-1 rounded-xl pl-3 pr-0"
    >
      <span
        v-if="!isEditing"
        class="block text-sm font-semibold capitalize"
        @click="startEditing"
      >
        {{ column.name }}
        <span>({{ localConversations.length }})</span>
      </span>

      <input
        v-else
        ref="inputRef"
        v-model="newName"
        class="table text-sm font-semibold capitalize bg-transparent focus:outline-none"
        autoFocus
        @keyup.enter="saveName"
        @blur="saveName"
      />

      <Button slate icon="i-lucide-x" @click="openDeleteModal" />
    </div>

    <div class="max-h-[84vh] overflow-auto relative">
      <p
        v-if="!localConversations.length"
        class="flex items-center justify-center p-4 text-sm text-n-slate-11"
      >
        {{ $t('CHAT_LIST.LIST.404') }}
      </p>

      <draggable
        v-model="localConversations"
        group="tasks"
        item-key="id"
        class="min-h-[79vh]"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <ConversationCard
            :conversation="element"
            :data-conversation-id="element.id"
            conversation-type="board"
          />
        </template>
      </draggable>

      <p class="p-4 text-center text-n-slate-11">
        {{ $t('CHAT_LIST.EOF') }}
      </p>
    </div>
  </div>
</template>
