<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({ editing: { type: Boolean, default: false } });
defineEmits(['edit', 'note', 'cancel']);
</script>

<template>
  <div
    class="flex items-center justify-between gap-3 p-4 border-t border-n-weak"
  >
    <p class="text-sm text-n-slate-11">
      {{
        editing
          ? $t('CONVERSATION.GOOGLE_PLAY_REPLY.EDITING')
          : $t('CONVERSATION.GOOGLE_PLAY_REPLY.SENT')
      }}
    </p>
    <div class="flex gap-2 shrink-0">
      <Button
        v-if="editing"
        :label="$t('CONVERSATION.GOOGLE_PLAY_REPLY.CANCEL')"
        variant="ghost"
        @click="$emit('cancel')"
      />
      <template v-else>
        <Button
          :label="$t('CONVERSATION.GOOGLE_PLAY_REPLY.NOTE')"
          variant="ghost"
          @click="$emit('note')"
        />
        <Button
          :label="$t('CONVERSATION.GOOGLE_PLAY_REPLY.EDIT')"
          @click="$emit('edit')"
        />
      </template>
    </div>
  </div>
</template>
