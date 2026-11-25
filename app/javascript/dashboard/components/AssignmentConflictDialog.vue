<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const OUTSIDE_WORKING_HOURS = 'outside_working_hours';

const dialogRef = ref(null);
const agentName = ref('');
const reason = ref('');

const isOutsideWorkingHours = computed(
  () => reason.value === OUTSIDE_WORKING_HOURS
);

const title = computed(() =>
  isOutsideWorkingHours.value
    ? t('CONVERSATION.ASSIGNMENT_CONFLICT.OUTSIDE_WORKING_HOURS.TITLE')
    : t('CONVERSATION.ASSIGNMENT_CONFLICT.TITLE')
);

const description = computed(() => {
  if (isOutsideWorkingHours.value) {
    return t(
      'CONVERSATION.ASSIGNMENT_CONFLICT.OUTSIDE_WORKING_HOURS.DESCRIPTION'
    );
  }
  return agentName.value
    ? t('CONVERSATION.ASSIGNMENT_CONFLICT.DESCRIPTION', {
        agentName: agentName.value,
      })
    : t('CONVERSATION.ASSIGNMENT_CONFLICT.DESCRIPTION_UNKNOWN_AGENT');
});

// Mounted once globally, next to the toast container, because the assignment
// actions that can collide live in four unrelated components (conversation
// sidebar, reply box banner, command bar and the chat list context menu).
const onAssignmentConflict = payload => {
  agentName.value = payload?.agentName || '';
  reason.value = payload?.reason || '';
  dialogRef.value?.open();
};

onMounted(() =>
  emitter.on(BUS_EVENTS.ASSIGNMENT_CONFLICT, onAssignmentConflict)
);
onUnmounted(() =>
  emitter.off(BUS_EVENTS.ASSIGNMENT_CONFLICT, onAssignmentConflict)
);
</script>

<template>
  <!-- Title and body live in the default slot rather than in the `title` and
  `description` props so the icon can sit beside them, and so the dialog does
  not render an empty content area between the text and the button. -->
  <Dialog
    ref="dialogRef"
    :show-cancel-button="false"
    :show-confirm-button="false"
    width="sm"
    @confirm="dialogRef?.close()"
  >
    <div class="flex items-start gap-4">
      <div
        class="flex items-center justify-center flex-shrink-0 size-10 rounded-xl bg-n-amber-3"
      >
        <span
          class="text-xl text-n-amber-11"
          :class="isOutsideWorkingHours ? 'i-lucide-clock' : 'i-lucide-lock'"
        />
      </div>
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium leading-6 text-n-slate-12">
          {{ title }}
        </h3>
        <p class="mb-0 text-sm text-n-slate-11">
          {{ description }}
        </p>
      </div>
    </div>
    <template #footer>
      <div class="flex justify-end w-full">
        <NextButton
          type="submit"
          :label="$t('CONVERSATION.ASSIGNMENT_CONFLICT.CONFIRM')"
        />
      </div>
    </template>
  </Dialog>
</template>
