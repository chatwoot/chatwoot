<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: null,
  },
  isLinking: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['link', 'dismiss']);

const { t } = useI18n();

const dialogRef = ref(null);

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  if (!props.inbox) return 'i-lucide-inbox';
  return getInboxIconByType(
    props.inbox.channelType,
    props.inbox.medium,
    'line'
  );
});

const openDialog = () => {
  dialogRef.value?.open();
};

const closeDialog = () => {
  dialogRef.value?.close();
};

const handleConfirm = () => {
  emit('link');
};

const handleClose = () => {
  emit('dismiss');
};

watch(
  () => props.inbox,
  async newInbox => {
    if (newInbox) {
      await nextTick();
      openDialog();
    } else {
      closeDialog();
    }
  },
  { immediate: true }
);

defineExpose({ openDialog, closeDialog });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.INBOX_LINK_PROMPT.TITLE'
      )
    "
    :confirm-button-label="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.INBOX_LINK_PROMPT.LINK_BUTTON'
      )
    "
    :cancel-button-label="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.INBOX_LINK_PROMPT.CANCEL_BUTTON'
      )
    "
    :is-loading="isLinking"
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <template #description>
      <p class="text-sm text-n-slate-11">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.INBOX_LINK_PROMPT.DESCRIPTION'
          )
        }}
      </p>
    </template>

    <div
      class="flex items-center gap-3 p-3 rounded-xl border border-n-weak bg-n-alpha-1"
    >
      <div
        class="flex-shrink-0 size-10 rounded-lg bg-n-alpha-2 flex items-center justify-center"
      >
        <i :class="inboxIcon" class="text-lg text-n-slate-11" />
      </div>
      <div class="flex flex-col min-w-0">
        <span class="text-sm font-medium text-n-slate-12 truncate">
          {{ inboxName }}
        </span>
      </div>
    </div>
  </Dialog>
</template>
