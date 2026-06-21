<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from './provider.js';
import { ORIENTATION } from './constants';
import MessageGenerationsAPI from 'dashboard/api/captain/messageGenerations';

const props = defineProps({
  messageId: { type: Number, required: true },
});

const { t } = useI18n();
const { orientation } = useMessageContext();

const isExpanded = ref(false);
const isLoading = ref(false);
const hasFetched = ref(false);
const generation = ref(null);

const reasoning = computed(() => generation.value?.reasoning);
const citations = computed(() => generation.value?.citations || []);
const generationPath = computed(() => generation.value?.generationPath || []);
const tools = computed(() =>
  generationPath.value.map(step => step?.tool).filter(Boolean)
);
// Model is only surfaced in development to aid debugging.
const model = computed(() =>
  import.meta.env.DEV ? generation.value?.model : null
);

const searchQuery = computed(() => {
  const step = generationPath.value.find(
    s => s?.tool === 'search_documentation'
  );
  return step?.arguments?.query || '';
});

const hasUsedCitation = computed(() => citations.value.some(c => c.used));

const sourcesSummary = computed(() => {
  const summary = t('CONVERSATION.CAPTAIN_GENERATION.SOURCES_SUMMARY', {
    count: citations.value.length,
  });
  if (!searchQuery.value) return summary;

  const searched = t('CONVERSATION.CAPTAIN_GENERATION.SEARCHED_FOR', {
    query: searchQuery.value,
  });
  return `${summary} · ${searched}`;
});

// Surface the FAQ(s) Captain actually used in the reply ahead of the rest.
const sortedCitations = computed(() =>
  [...citations.value].sort((a, b) => Number(b.used) - Number(a.used))
);

const hasDetails = computed(
  () =>
    Boolean(reasoning.value) ||
    citations.value.length > 0 ||
    tools.value.length > 0
);

const rowAlignClass = computed(() =>
  orientation.value === ORIENTATION.LEFT ? 'justify-start' : 'justify-end'
);

const fetchGeneration = async () => {
  if (hasFetched.value) return;

  isLoading.value = true;
  try {
    const { data } = await MessageGenerationsAPI.show(props.messageId);
    generation.value = useCamelCase(data, { deep: true });
  } catch (error) {
    generation.value = null;
  } finally {
    hasFetched.value = true;
    isLoading.value = false;
  }
};

const toggle = () => {
  isExpanded.value = !isExpanded.value;
  if (isExpanded.value) fetchGeneration();
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <Transition
      enter-active-class="transition-[opacity,transform] duration-200 ease-out"
      enter-from-class="opacity-0 translate-y-1"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition-[opacity,transform] duration-150 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 translate-y-1"
    >
      <div
        v-if="isExpanded"
        class="flex flex-col gap-3 p-3 text-xs rounded-lg bg-n-alpha-black1"
      >
        <span v-if="isLoading">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.LOADING') }}
        </span>
        <span v-else-if="!hasDetails">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.EMPTY') }}
        </span>
        <template v-else>
          <div v-if="reasoning" class="flex flex-col gap-1">
            <span class="font-medium opacity-70">
              {{ t('CONVERSATION.CAPTAIN_GENERATION.REASONING') }}
            </span>
            <p class="m-0 whitespace-pre-line">{{ reasoning }}</p>
          </div>
          <div v-if="citations.length" class="flex flex-col gap-1.5">
            <span class="font-medium opacity-70">
              {{ t('CONVERSATION.CAPTAIN_GENERATION.SOURCES') }}
            </span>
            <p class="m-0 opacity-70">{{ sourcesSummary }}</p>
            <ul class="flex flex-col gap-1 m-0 list-disc ps-4">
              <li
                v-for="(citation, index) in sortedCitations"
                :key="index"
                :class="[
                  { 'opacity-50': hasUsedCitation && !citation.used },
                  citation.used ? 'font-medium' : '',
                ]"
              >
                <a
                  v-if="citation.source"
                  :href="citation.source"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-blue-11 hover:underline"
                >
                  {{ citation.title || citation.source }}
                </a>
                <span v-else>{{ citation.title }}</span>
                <span
                  v-if="citation.used"
                  class="px-1 ml-1 rounded bg-n-alpha-2 text-n-teal-10"
                >
                  {{ t('CONVERSATION.CAPTAIN_GENERATION.USED') }}
                </span>
              </li>
            </ul>
          </div>
          <div v-if="tools.length" class="flex flex-col gap-1">
            <span class="font-medium opacity-70">
              {{ t('CONVERSATION.CAPTAIN_GENERATION.TOOLS') }}
            </span>
            <ul class="flex flex-col gap-1 m-0 list-disc ps-4">
              <li v-for="(tool, index) in tools" :key="index">{{ tool }}</li>
            </ul>
          </div>
          <span v-if="model" class="opacity-70">
            {{ t('CONVERSATION.CAPTAIN_GENERATION.MODEL', { model }) }}
          </span>
        </template>
      </div>
    </Transition>
    <div class="flex items-center gap-1.5" :class="rowAlignClass">
      <slot name="meta" />
      <button
        v-tooltip="t('CONVERSATION.CAPTAIN_GENERATION.TITLE')"
        type="button"
        class="inline-flex items-center justify-center bg-transparent border-0 cursor-pointer text-n-slate-10 hover:text-n-slate-11"
        :class="isExpanded ? 'text-n-slate-11' : ''"
        @click="toggle"
      >
        <Icon icon="i-ph-sparkle-fill" class="size-3.5" />
      </button>
    </div>
  </div>
</template>
