<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { Virtualizer } from 'virtua/vue';

import {
  buildEmojiSections,
  getEmojiTint,
  getRecentEmojis,
  addRecentEmoji,
} from 'shared/components/emoji/pickerHelper';

const emit = defineEmits(['select']);

const { t } = useI18n();

const emojiSearch = ref('');
const recentEmojis = ref([]);
const searchInput = ref(null);

onMounted(() => {
  recentEmojis.value = getRecentEmojis();
  searchInput.value?.focus();
});

const emojiSections = computed(() =>
  buildEmojiSections(
    emojiSearch.value,
    recentEmojis.value,
    t('EMOJI_ICON_PICKER.FREQUENTLY_USED')
  )
);

// Tints an emoji button with a light shade of the emoji's own color on hover.
const applyEmojiTint = (event, emoji) => {
  event.currentTarget.style.setProperty('--ep-tint', getEmojiTint(emoji));
};

const selectEmoji = emoji => {
  recentEmojis.value = addRecentEmoji(emoji);
  emit('select', { type: 'emoji', value: emoji.emoji, emoji: emoji.emoji });
};
</script>

<template>
  <div
    role="dialog"
    class="absolute z-20 flex flex-col overflow-hidden shadow-xl w-[22rem] bg-n-surface-2 backdrop-blur-[100px] rounded-2xl outline outline-1 outline-n-weak dark:outline-n-strong/50"
  >
    <div class="flex flex-col gap-1.5 pt-2">
      <div class="relative px-2">
        <span
          class="absolute z-10 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10 top-1/2 start-5"
        />
        <input
          ref="searchInput"
          v-model="emojiSearch"
          type="text"
          class="block w-full h-10 text-sm reset-base outline outline-1 outline-offset-[-1px] outline-n-weak focus:outline-n-brand border-none rounded-lg !ps-9 !pe-3 !py-2.5 bg-transparent text-n-slate-12 placeholder:text-n-slate-10"
          :placeholder="t('EMOJI_ICON_PICKER.SEARCH_EMOJI')"
        />
      </div>
      <div
        v-if="emojiSections.length"
        class="h-60 overflow-y-auto px-2 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        <Virtualizer v-slot="{ item: section }" :data="emojiSections">
          <h5
            class="px-1 pt-2 pb-1 m-0 text-xs font-medium tracking-wide uppercase text-n-slate-10"
          >
            {{ section.name }}
          </h5>
          <div class="grid grid-cols-10 gap-0.5">
            <button
              v-for="emoji in section.emojis"
              :key="`${section.name}-${emoji.slug}`"
              type="button"
              :title="emoji.name"
              class="flex items-center justify-center !p-0 w-full max-w-[2rem] text-xl transition-colors rounded-lg aspect-square hover:bg-[var(--ep-tint)] active:enabled:scale-[0.97]"
              @mouseenter="applyEmojiTint($event, emoji.emoji)"
              @click="selectEmoji(emoji)"
            >
              {{ emoji.emoji }}
            </button>
          </div>
        </Virtualizer>
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center gap-2 h-60 text-n-slate-10"
      >
        <span class="i-lucide-smile-plus size-7" />
        <span class="text-sm font-medium">
          {{ t('EMOJI_ICON_PICKER.NO_EMOJI') }}
        </span>
      </div>
    </div>
  </div>
</template>
