<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import MessagePreview from 'dashboard/components/widgets/conversation/MessagePreview.vue';

defineProps({
  message: { type: Object, required: true },
});

const emit = defineEmits(['jump']);
</script>

<template>
  <div
    class="mx-4 mb-4 rounded-lg border border-n-slate-3 p-3 flex flex-col gap-2"
  >
    <p class="text-xs font-medium text-n-slate-11">
      {{ $t('INTERNAL_TASKS.INBOX.ANCHORED_MESSAGE') }}
    </p>
    <MessagePreview
      :message="message"
      :show-message-type="false"
      class="text-sm"
    />
    <Button
      variant="outline"
      size="xs"
      color="blue"
      :label="$t('INTERNAL_TASKS.INBOX.JUMP_TO_MESSAGE')"
      @click="emit('jump')"
    />
  </div>
</template>
