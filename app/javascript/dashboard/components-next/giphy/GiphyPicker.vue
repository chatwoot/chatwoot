<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn, useInfiniteScroll } from '@vueuse/core';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import GiphyAPI from 'dashboard/api/integrations/giphy';

import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['select', 'close']);

const SEARCH_DEBOUNCE_MS = 300;
const SKELETON_TILES = 8;

const { t } = useI18n();
const { run, isPending } = useAbortableRequest();
const resultsRef = ref(null);

const query = ref('');
const gifs = ref([]);
const nextOffset = ref(0);
const hasError = ref(false);

const isSearching = computed(() => Boolean(query.value.trim()));
const showSkeleton = computed(() => isPending.value && !gifs.value.length);

const fetchGifs = async (offset = 0) => {
  hasError.value = false;
  try {
    const response = await run(signal =>
      GiphyAPI.search({ query: query.value.trim(), offset, signal })
    );
    // Superseded by a newer search.
    if (!response) return;

    const { gifs: results, next_offset: next } = response.data;
    gifs.value = offset ? [...gifs.value, ...results] : results;
    nextOffset.value = next;
  } catch {
    hasError.value = true;
  }
};

const search = useDebounceFn(() => {
  resultsRef.value?.scrollTo({ top: 0 });
  gifs.value = [];
  fetchGifs();
}, SEARCH_DEBOUNCE_MS);

watch(query, search);

useInfiniteScroll(
  resultsRef,
  () => {
    if (nextOffset.value && !isPending.value) fetchGifs(nextOffset.value);
  },
  { distance: 120 }
);

onMounted(() => fetchGifs());
</script>

<template>
  <div
    class="flex flex-col overflow-hidden shadow-xl w-[22rem] bg-n-surface-2 backdrop-blur-[100px] rounded-2xl outline outline-1 outline-n-weak dark:outline-n-strong/50"
  >
    <div class="px-2 pt-2">
      <Input
        v-model="query"
        size="md"
        :placeholder="t('CONVERSATION.REPLYBOX.GIPHY.SEARCH_PLACEHOLDER')"
        custom-input-class="!ps-9 !bg-transparent"
        autofocus
        @keydown.enter.prevent
        @keydown.esc.stop="emit('close')"
      >
        <template #prefix>
          <span
            class="absolute z-10 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10 top-1/2 start-3"
          />
        </template>
      </Input>
    </div>

    <h5
      class="px-3 pt-2 pb-1 m-0 text-xs font-medium tracking-wide uppercase text-n-slate-10"
    >
      {{
        isSearching
          ? t('CONVERSATION.REPLYBOX.GIPHY.RESULTS')
          : t('CONVERSATION.REPLYBOX.GIPHY.TRENDING')
      }}
    </h5>

    <div ref="resultsRef" class="px-2 pb-2 overflow-y-auto h-72 no-scrollbar">
      <div
        v-if="hasError || (!gifs.length && !isPending)"
        class="flex flex-col items-center justify-center h-full gap-2 text-n-slate-10"
      >
        <span
          :class="hasError ? 'i-lucide-cloud-off' : 'i-lucide-search-x'"
          class="size-7"
        />
        <span class="text-sm font-medium">
          {{
            hasError
              ? t('CONVERSATION.REPLYBOX.GIPHY.ERROR')
              : t('CONVERSATION.REPLYBOX.GIPHY.EMPTY')
          }}
        </span>
      </div>

      <div v-else class="gap-1.5 columns-2">
        <template v-if="showSkeleton">
          <div
            v-for="tile in SKELETON_TILES"
            :key="tile"
            class="mb-1.5 rounded-lg break-inside-avoid bg-n-alpha-2 animate-pulse"
            :class="tile % 3 ? 'h-24' : 'h-32'"
          />
        </template>
        <button
          v-for="gif in gifs"
          :key="gif.id"
          type="button"
          class="block w-full !p-0 mb-1.5 overflow-hidden transition-transform rounded-lg break-inside-avoid bg-n-alpha-2 hover:opacity-90 active:scale-[0.98] focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
          :title="gif.title"
          @click="emit('select', gif)"
        >
          <img
            :src="gif.preview_url"
            :alt="gif.title"
            :width="gif.width"
            :height="gif.height"
            loading="lazy"
            class="block w-full h-auto"
          />
        </button>
      </div>
    </div>

    <div
      class="flex items-center justify-end px-3 py-2 text-xs font-medium border-t border-n-weak text-n-slate-10"
    >
      {{ t('CONVERSATION.REPLYBOX.GIPHY.ATTRIBUTION') }}
    </div>
  </div>
</template>
