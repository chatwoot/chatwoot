<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { Virtualizer } from 'virtua/vue';
import {
  addRecentEmoji,
  buildEmojiSections,
  getRecentEmojis,
} from 'shared/components/emoji/pickerHelper';

const emit = defineEmits(['select']);

const { t } = useI18n();

const search = ref('');
const recentEmojis = ref([]);
const searchRef = ref(null);

onMounted(() => {
  recentEmojis.value = getRecentEmojis();
  searchRef.value?.focus();
});

const sections = computed(() =>
  buildEmojiSections(
    search.value,
    recentEmojis.value,
    t('EMOJI.FREQUENTLY_USED')
  )
);

const select = emoji => {
  recentEmojis.value = addRecentEmoji(emoji);
  emit('select', emoji.emoji);
};
</script>

<template>
  <div
    role="dialog"
    class="surface-card absolute bottom-full start-0 end-0 z-20 mb-2 flex flex-col overflow-hidden"
  >
    <div class="relative p-2">
      <span
        class="absolute top-1/2 start-4 -translate-y-1/2 i-ph-magnifying-glass text-cw-text-faint"
      />
      <input
        ref="searchRef"
        v-model="search"
        type="text"
        class="w-full h-9 ps-8 pe-3 text-sm bg-cw-muted text-cw-text placeholder:text-cw-text-faint rounded-token-sm border-none outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :placeholder="$t('EMOJI.SEARCH')"
      />
    </div>

    <div
      v-if="sections.length"
      class="h-52 overflow-y-auto scrollbar-thin px-2 pb-2"
    >
      <Virtualizer v-slot="{ item: section }" :data="sections">
        <h5 class="px-1 pt-2 pb-1 m-0 text-cw-text-faint type-overline">
          {{ section.name }}
        </h5>
        <div class="grid grid-cols-8 gap-0.5">
          <button
            v-for="emoji in section.emojis"
            :key="`${section.name}-${emoji.slug}`"
            type="button"
            :title="emoji.name"
            class="flex items-center justify-center w-full aspect-square text-xl rounded-token-sm hover:bg-cw-muted outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
            @click="select(emoji)"
          >
            {{ emoji.emoji }}
          </button>
        </div>
      </Virtualizer>
    </div>
    <p
      v-else
      class="flex items-center justify-center h-52 text-sm text-cw-text-muted"
    >
      {{ $t('EMOJI.NO_RESULTS') }}
    </p>
  </div>
</template>
