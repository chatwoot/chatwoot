<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import {
  renderInlineDiff,
  buildDiffBlocks,
} from 'dashboard/helper/articleDiffHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
});

const isOpen = defineModel({ type: Boolean, default: false });

const { t } = useI18n();

const liveTitle = computed(() => props.article?.title ?? '');
const liveContent = computed(() => props.article?.content ?? '');
const draftTitle = computed(() => props.article?.draftTitle ?? liveTitle.value);
const draftContent = computed(
  () => props.article?.draftContent ?? liveContent.value
);

const titleChanged = computed(() => liveTitle.value !== draftTitle.value);
const titleDiff = computed(() =>
  renderInlineDiff(liveTitle.value, draftTitle.value)
);

const contentBlocks = computed(() =>
  buildDiffBlocks(liveContent.value, draftContent.value)
);
const contentChanged = computed(() =>
  contentBlocks.value.some(block => block.type !== 'equal')
);

// HC tables store per-column widths (px, 0 = unset) in this marker, which the
// formatter strips. Re-apply them as a fixed-layout <colgroup>, defaulting
// unsized columns so they don't collapse.
const COLWIDTHS_RE = /<!--cw-colwidths:([\d,]+)-->/;
const DEFAULT_COL_WIDTH = 50;

const applyColumnWidths = (html, widths) => {
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const table = doc.body.querySelector('table');
  if (!table) return html;

  const sized = widths.map(width => (width > 0 ? width : DEFAULT_COL_WIDTH));
  const colgroup = doc.createElement('colgroup');
  sized.forEach(width => {
    const col = doc.createElement('col');
    col.style.width = `${width}px`;
    colgroup.appendChild(col);
  });
  table.insertBefore(colgroup, table.firstChild);

  table.style.tableLayout = 'fixed';
  table.style.width = `${sized.reduce((sum, width) => sum + width, 0)}px`;
  return doc.body.innerHTML;
};

const renderMarkdown = markdown => {
  if (!markdown) return '';
  const html = new MessageFormatter(markdown).formattedMessage;
  const match = markdown.match(COLWIDTHS_RE);
  return match
    ? applyColumnWidths(html, match[1].split(',').map(Number))
    : html;
};

const blockClass = type => {
  if (type === 'added') {
    return 'border-n-teal-9 bg-n-teal-2';
  }
  if (type === 'removed') {
    return 'border-n-ruby-9 bg-n-ruby-2 line-through decoration-n-ruby-9/50';
  }
  return 'border-transparent';
};

const close = () => {
  isOpen.value = false;
};

const dismissOnClickOutside = [close, { ignore: ['[data-diff-toggle]'] }];

useKeyboardEvents({ Escape: { action: close, allowOnFocusedInput: true } });
</script>

<template>
  <TeleportWithDirection to="body">
    <Transition
      enter-active-class="transition-transform duration-200 ease-in-out"
      leave-active-class="transition-transform duration-200 ease-in-out"
      enter-from-class="ltr:translate-x-full rtl:-translate-x-full"
      enter-to-class="ltr:translate-x-0 rtl:-translate-x-0"
      leave-from-class="ltr:translate-x-0 rtl:-translate-x-0"
      leave-to-class="ltr:translate-x-full rtl:-translate-x-full"
    >
      <aside
        v-if="isOpen"
        v-on-click-outside="dismissOnClickOutside"
        class="fixed inset-y-0 z-40 flex flex-col w-full shadow-2xl end-0 max-w-lg bg-n-solid-2 ltr:border-l rtl:border-r border-n-weak"
      >
        <header
          class="flex items-start justify-between gap-3 px-6 py-4 border-b shrink-0 border-n-weak bg-n-solid-1"
        >
          <div class="flex flex-col gap-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="size-2 rounded-full bg-n-amber-9 shrink-0" />
              <h3 class="text-base font-medium leading-6 text-n-slate-12">
                {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.DIFF_DIALOG.TITLE') }}
              </h3>
            </div>
            <p class="text-sm text-n-slate-11">
              {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.DIFF_DIALOG.DESCRIPTION') }}
            </p>
          </div>
          <Button
            icon="i-lucide-x"
            variant="ghost"
            color="slate"
            size="sm"
            class="shrink-0 hover:text-n-slate-11"
            @click="close"
          />
        </header>

        <div
          class="flex flex-col flex-1 min-h-0 gap-4 px-6 pt-4 pb-6 overflow-y-auto"
        >
          <!-- eslint-disable vue/no-v-html -->
          <div
            v-if="titleChanged"
            class="flex flex-col gap-1.5 border-s-[3px] border-transparent ps-3"
          >
            <span
              class="text-[11px] font-medium tracking-wide uppercase text-n-slate-10"
            >
              {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.DIFF_DIALOG.TITLE_LABEL') }}
            </span>
            <h1
              class="text-lg font-semibold leading-snug text-n-slate-12"
              v-html="titleDiff"
            />
          </div>

          <div
            v-if="contentChanged"
            class="flex flex-col gap-1 [&_table]:w-full [&_table]:border-collapse [&_th]:border [&_td]:border [&_th]:border-n-weak [&_td]:border-n-weak [&_th]:p-2 [&_td]:p-2 [&_th]:bg-n-alpha-1 [&_th]:text-start [&_td]:align-top"
          >
            <div
              v-for="(block, index) in contentBlocks"
              :key="index"
              class="px-3 py-1.5 overflow-x-auto text-sm leading-relaxed break-words border-s-[3px] rounded-e-md text-n-slate-12 prose-sm prose dark:prose-invert max-w-none [&_p]:my-0 [&>:first-child]:mt-0 [&>:last-child]:mb-0"
              :class="blockClass(block.type)"
              v-html="renderMarkdown(block.md)"
            />
          </div>
          <!-- eslint-enable vue/no-v-html -->
        </div>
      </aside>
    </Transition>
  </TeleportWithDirection>
</template>
