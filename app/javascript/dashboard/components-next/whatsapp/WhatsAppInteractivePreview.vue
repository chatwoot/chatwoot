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
  cards: { type: Array, default: () => [] },
  actionMode: { type: String, default: '' },
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
      v-else-if="type === 'carousel'"
      class="flex gap-3 overflow-x-auto pb-2"
      data-testid="whatsapp-carousel-preview"
    >
      <article
        v-for="(card, cardIndex) in cards"
        :key="card.clientKey || cardIndex"
        class="flex w-56 shrink-0 flex-col gap-2 rounded-lg border border-n-weak p-2"
      >
        <img
          v-if="card.media"
          :src="card.media.dataUrl"
          :alt="
            $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.CARD_IMAGE_ALT', {
              number: cardIndex + 1,
            })
          "
          class="h-32 w-full rounded-lg object-cover"
        />
        <div
          v-else
          class="flex h-32 items-center justify-center rounded-lg bg-n-alpha-1 text-xs text-n-slate-11"
        >
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.IMAGE_REQUIRED') }}
        </div>
        <p v-if="card.body" class="mb-0 whitespace-pre-wrap break-words">
          {{ card.body }}
        </p>
        <template v-if="actionMode === 'url'">
          <button
            type="button"
            disabled
            class="w-full rounded-lg bg-n-alpha-2 px-3 py-2 text-sm font-medium text-n-blue-11 disabled:cursor-default disabled:opacity-100"
          >
            {{ card.action.button }}
          </button>
          <p class="mb-0 break-all text-xs text-n-slate-11">
            {{ card.action.url }}
          </p>
        </template>
        <div
          v-else-if="actionMode === 'quick_reply'"
          class="flex flex-col gap-1"
        >
          <button
            v-for="(reply, replyIndex) in card.action.buttons"
            :key="reply.clientKey || reply.preset_option_id || replyIndex"
            type="button"
            disabled
            class="w-full rounded-lg bg-n-alpha-2 px-3 py-2 text-sm font-medium text-n-blue-11 disabled:cursor-default disabled:opacity-100"
          >
            {{ reply.title }}
          </button>
        </div>
      </article>
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
