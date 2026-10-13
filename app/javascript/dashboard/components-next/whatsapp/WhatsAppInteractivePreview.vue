<script setup>
defineProps({
  type: { type: String, default: 'button' },
  body: { type: String, default: '' },
  header: { type: Object, default: null },
  attachment: { type: Object, default: null },
  footer: { type: String, default: '' },
  buttons: { type: Array, default: () => [] },
  opener: { type: String, default: '' },
  url: { type: String, default: '' },
  sections: { type: Array, default: () => [] },
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
    <div
      v-if="type === 'button'"
      class="flex flex-col gap-2 border-t border-n-weak pt-2"
    >
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
    <div
      v-else-if="type === 'cta_url'"
      class="flex flex-col gap-2 border-t border-n-weak pt-2"
    >
      <button
        type="button"
        disabled
        class="w-full rounded-lg px-3 py-2 text-sm font-medium text-n-blue-11 bg-n-alpha-2 disabled:cursor-default disabled:opacity-100"
      >
        {{ opener }}
      </button>
      <p
        class="mb-0 text-xs text-n-slate-11 break-all"
        data-testid="whatsapp-cta-destination"
      >
        {{ url }}
      </p>
    </div>
    <div
      v-else-if="type === 'list'"
      class="flex flex-col gap-3 border-t border-n-weak pt-2"
    >
      <button
        type="button"
        disabled
        class="w-full rounded-lg px-3 py-2 text-sm font-medium text-n-blue-11 bg-n-alpha-2 disabled:cursor-default disabled:opacity-100"
      >
        {{ opener }}
      </button>
      <section
        v-for="(section, sectionIndex) in sections"
        :key="sectionIndex"
        class="flex flex-col gap-2"
      >
        <h5 v-if="section.title" class="mb-0 text-sm font-medium break-words">
          {{ section.title }}
        </h5>
        <div
          v-for="(row, rowIndex) in section.rows"
          :key="rowIndex"
          class="rounded-lg bg-n-alpha-1 px-3 py-2"
        >
          <p class="mb-0 text-sm font-medium break-words">{{ row.title }}</p>
          <p
            v-if="row.description"
            class="mb-0 text-xs text-n-slate-11 break-words"
          >
            {{ row.description }}
          </p>
        </div>
      </section>
    </div>
  </div>
</template>
