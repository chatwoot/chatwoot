<script setup>
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  note: {
    type: Object,
    required: true,
  },
  writtenBy: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['delete']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const handleDelete = () => {
  emit('delete', props.note.id);
};
</script>

<template>
  <div
    class="flex flex-col gap-2 px-6 py-2 border-b border-n-strong group/note"
  >
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-1.5 py-2.5 min-w-0">
        <Avatar
          :name="note.user.name"
          :src="note.user.thumbnail"
          :size="16"
          rounded-full
        />
        <div class="min-w-0 truncate">
          <span class="inline-flex items-center gap-1 text-sm text-n-slate-11">
            <span class="font-medium">{{ writtenBy }}</span>
            {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.WROTE') }}
            <span class="font-medium">{{ dynamicTime(note.createdAt) }}</span>
          </span>
        </div>
      </div>
      <Button
        variant="faded"
        color="ruby"
        size="xs"
        icon="i-lucide-trash"
        class="opacity-0 group-hover/note:opacity-100"
        @click="handleDelete"
      />
    </div>
    <p
      v-dompurify-html="formatMessage(note.content || '')"
      class="mb-0 prose-sm prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
    />
  </div>
</template>
