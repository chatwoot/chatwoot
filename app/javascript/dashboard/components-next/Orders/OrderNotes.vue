<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  orderId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const noteContent = ref('');

const currentUser = useMapGetter('getCurrentUser');
const notesByOrder = useMapGetter('orderNotes/getNotesByOrderId');
const uiFlags = useMapGetter('orderNotes/getUIFlags');

const isFetching = computed(() => uiFlags.value.isFetching);
const isCreating = computed(() => uiFlags.value.isCreating);
const notes = computed(() => notesByOrder.value(props.orderId));

const getWrittenBy = note => {
  const isCurrentUser = note?.user?.id === currentUser.value.id;
  return isCurrentUser
    ? t('ORDER_DETAILS.NOTES.YOU')
    : note?.user?.name || 'Bot';
};

const onAdd = () => {
  const content = noteContent.value.trim();
  if (!content) return;
  store.dispatch('orderNotes/create', {
    orderId: props.orderId,
    content,
  });
  noteContent.value = '';
};

const onDelete = noteId => {
  if (!noteId) return;
  store.dispatch('orderNotes/delete', {
    noteId,
    orderId: props.orderId,
  });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div class="flex flex-col gap-4 px-6">
    <h3 class="text-sm font-semibold text-n-slate-12">
      {{ t('ORDER_DETAILS.NOTES.TITLE') }}
    </h3>

    <!-- Note Input -->
    <div class="flex flex-col gap-2">
      <textarea
        v-model="noteContent"
        :placeholder="t('ORDER_DETAILS.NOTES.PLACEHOLDER')"
        class="w-full min-h-[5rem] p-3 text-sm border rounded-lg resize-none bg-n-background border-n-weak text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-1 focus:ring-n-brand"
        @keydown.meta.enter="onAdd"
        @keydown.ctrl.enter="onAdd"
      />
      <div class="flex justify-end">
        <Button
          size="sm"
          :label="t('ORDER_DETAILS.NOTES.SAVE')"
          :is-loading="isCreating"
          :disabled="!noteContent.trim() || isCreating"
          @click="onAdd"
        />
      </div>
    </div>

    <!-- Notes List -->
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="notes.length > 0" class="flex flex-col">
      <div
        v-for="note in notes"
        :key="note.id"
        class="flex flex-col gap-2 py-4 border-b border-n-weak group/note"
      >
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-1.5 min-w-0">
            <Avatar
              :name="note?.user?.name || 'Bot'"
              :src="
                note?.user?.name
                  ? note?.user?.thumbnail
                  : '/assets/images/chatwoot_bot.png'
              "
              :size="16"
              rounded-full
            />
            <span class="text-sm text-n-slate-11 truncate">
              <span class="font-medium text-n-slate-12">{{
                getWrittenBy(note)
              }}</span>
              {{ t('ORDER_DETAILS.NOTES.WROTE') }}
              <span class="font-medium text-n-slate-12">{{
                dynamicTime(note.created_at)
              }}</span>
            </span>
          </div>
          <Button
            variant="faded"
            color="ruby"
            size="xs"
            icon="i-lucide-trash"
            class="opacity-0 group-hover/note:opacity-100"
            @click="onDelete(note.id)"
          />
        </div>
        <p class="mb-0 text-sm text-n-slate-12 leading-relaxed">
          {{ note.content }}
        </p>
      </div>
    </div>
    <p v-else class="py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('ORDER_DETAILS.NOTES.EMPTY_STATE') }}
    </p>
  </div>
</template>
