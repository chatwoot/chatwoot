<script setup>
import { computed, useTemplateRef, nextTick, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useToggle } from '@vueuse/core';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  note: {
    type: Object,
    required: true,
  },
  writtenBy: {
    type: String,
    required: true,
  },
  allowDelete: {
    type: Boolean,
    default: false,
  },
  allowEdit: {
    type: Boolean,
    default: false,
  },
  collapsible: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete', 'update']);
const noteContentRef = useTemplateRef('noteContentRef');
const needsCollapse = ref(false);
const isEditing = ref(false);
const draftContent = ref(props.note.content || '');
const [isExpanded, toggleExpanded] = useToggle();
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const canSave = computed(
  () => draftContent.value && draftContent.value !== (props.note.content || '')
);
const hasUpdatedMetadata = computed(() => {
  const createdAt = Number(props.note.createdAt);
  const updatedAt = Number(props.note.updatedAt);
  const createdById = props.note.user?.id;
  const updatedById = props.note.updatedBy?.id;
  const hasEditTimestamp = updatedAt > createdAt;
  const hasDifferentUpdater =
    updatedById && createdById && updatedById !== createdById;

  return Boolean(
    props.note.updatedBy?.name &&
      props.note.updatedAt &&
      (hasEditTimestamp || hasDifferentUpdater)
  );
});

const updateCollapseState = async () => {
  if (!props.collapsible || isEditing.value) {
    needsCollapse.value = false;
    return;
  }

  await nextTick();

  // Check if content height exceeds approximately 4 lines.
  // Assuming line height is ~1.625 and font size is ~14px.
  const threshold = 14 * 1.625 * 4; // ~84px
  needsCollapse.value = noteContentRef.value?.clientHeight > threshold;
};

const handleEdit = () => {
  draftContent.value = props.note.content || '';
  isEditing.value = true;
};

const handleCancel = () => {
  draftContent.value = props.note.content || '';
  isEditing.value = false;
};

const handleUpdate = () => {
  if (!canSave.value) return;

  emit('update', { noteId: props.note.id, content: draftContent.value });
  isEditing.value = false;
};

const handleDelete = () => {
  emit('delete', props.note.id);
};

watch(
  () => props.note.content,
  content => {
    if (!isEditing.value) {
      draftContent.value = content || '';
      updateCollapseState();
    }
  }
);

watch(isEditing, editing => {
  if (!editing) {
    updateCollapseState();
  }
});

onMounted(() => {
  updateCollapseState();
});
</script>

<template>
  <div class="flex flex-col gap-2 border-b border-n-strong group/note">
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
        <div class="min-w-0 truncate">
          <span class="flex flex-wrap items-center gap-x-2 gap-y-0.5">
            <span
              class="inline-flex items-center gap-1 text-sm text-n-slate-11"
            >
              <span class="font-medium text-n-slate-12">{{ writtenBy }}</span>
              {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.WROTE') }}
              <span class="font-medium text-n-slate-12">
                {{ dynamicTime(note.createdAt) }}
              </span>
            </span>
            <span
              v-if="hasUpdatedMetadata"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.UPDATED') }}
              <span class="font-medium text-n-slate-11">
                {{ note.updatedBy.name }}
              </span>
              <span class="font-medium text-n-slate-11">
                {{ dynamicTime(note.updatedAt) }}
              </span>
            </span>
          </span>
        </div>
      </div>
      <div class="flex items-center gap-1">
        <Button
          v-if="allowEdit && !isEditing"
          data-test-id="contact-note-edit"
          variant="faded"
          color="slate"
          size="xs"
          icon="i-lucide-pencil"
          :aria-label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EDIT')"
          :title="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EDIT')"
          class="opacity-0 group-hover/note:opacity-100 group-focus-within/note:opacity-100 focus:opacity-100"
          @click="handleEdit"
        />
        <Button
          v-if="allowDelete && !isEditing"
          variant="faded"
          color="ruby"
          size="xs"
          icon="i-lucide-trash"
          class="opacity-0 group-hover/note:opacity-100 group-focus-within/note:opacity-100 focus:opacity-100"
          @click="handleDelete"
        />
      </div>
    </div>
    <Editor
      v-if="isEditing"
      v-model="draftContent"
      :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
      focus-on-mount
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4"
    >
      <template #actions>
        <div class="flex items-center justify-end gap-2">
          <Button
            data-test-id="contact-note-cancel"
            variant="faded"
            color="slate"
            size="xs"
            :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.CANCEL')"
            @click="handleCancel"
          />
          <Button
            data-test-id="contact-note-save"
            variant="solid"
            color="blue"
            size="xs"
            :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.UPDATE')"
            :disabled="!canSave"
            @click="handleUpdate"
          />
        </div>
      </template>
    </Editor>
    <p
      v-else
      ref="noteContentRef"
      v-dompurify-html="formatMessage(note.content || '')"
      class="mb-0 prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
      :class="{
        'line-clamp-4': collapsible && !isExpanded && needsCollapse,
      }"
    />
    <p v-if="!isEditing && collapsible && needsCollapse">
      <Button
        variant="faded"
        color="blue"
        size="xs"
        :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="() => toggleExpanded()"
      >
        <template v-if="isExpanded">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.COLLAPSE') }}
        </template>
        <template v-else>
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EXPAND') }}
        </template>
      </Button>
    </p>
  </div>
</template>
