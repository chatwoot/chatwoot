<script setup>
defineProps({
  body: { type: String, default: '' },
  header: { type: Object, default: null },
  attachment: { type: Object, default: null },
  footer: { type: String, default: '' },
  buttons: { type: Array, default: () => [] },
});
</script>

<template>
  <div class="flex flex-col gap-3 min-w-64 max-w-lg">
    <p v-if="header?.type === 'text'" class="mb-0 font-semibold break-words">
      {{ header.text }}
    </p>
    <img
      v-else-if="header?.type === 'image' && attachment"
      :src="attachment.dataUrl"
      :alt="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_IMAGE')"
      class="max-h-64 rounded-lg object-contain"
    />
    <video
      v-else-if="header?.type === 'video' && attachment"
      :src="attachment.dataUrl"
      :aria-label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_VIDEO')"
      controls
      preload="metadata"
      class="max-h-64 rounded-lg"
    />
    <a
      v-else-if="header?.type === 'document' && attachment"
      :href="attachment.dataUrl"
      target="_blank"
      rel="noopener noreferrer"
      class="rounded-lg border border-n-weak p-3 text-n-blue-11 break-words"
    >
      {{
        attachment.name ||
        $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_DOCUMENT')
      }}
    </a>
    <p class="mb-0 whitespace-pre-wrap break-words">{{ body }}</p>
    <p v-if="footer" class="mb-0 text-xs text-n-slate-11 break-words">
      {{ footer }}
    </p>
    <div class="flex flex-col gap-2 border-t border-n-weak pt-2">
      <button
        v-for="(button, index) in buttons"
        :key="index"
        type="button"
        disabled
        class="w-full rounded-lg px-3 py-2 text-sm font-medium text-n-blue-11 bg-n-alpha-2 disabled:cursor-default disabled:opacity-100"
      >
        {{ button.title }}
      </button>
    </div>
  </div>
</template>
