<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import { embeds } from 'dashboard/helper/markdownEmbeds';
import {
  renderInlineDiff,
  buildDiffBlocks,
} from 'dashboard/helper/articleDiffHelper';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';

const props = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const panelRef = ref(null);

defineExpose({
  open: () => panelRef.value?.open(),
  close: () => panelRef.value?.close(),
});

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

const applyColumnWidths = (doc, widths) => {
  const table = doc.body.querySelector('table');
  if (!table) return;

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
};

// Match the portal renderer: solo video links become players, sized by their
// cw_video_width param. (Images are sized by MessageFormatter itself.)
const videoEmbeds = embeds.filter(embed => embed.hideSource);
const DEFAULT_VIDEO_WIDTH = 640;

const savedVideoWidth = href => {
  const width = Number(href.match(/[?&]cw_video_width=(\d+)px(?:[&#]|$)/)?.[1]);
  return width >= 1 && width <= 2000 ? width : null;
};

const applyVideoPreviews = doc => {
  doc.body.querySelectorAll('p > a:only-child').forEach(link => {
    const href = link.getAttribute('href');
    if (!href || !videoEmbeds.some(({ regex }) => regex.test(href))) return;
    const paragraph = link.parentElement;
    if (paragraph.textContent.trim() !== link.textContent.trim()) return;

    const video = Object.assign(doc.createElement('video'), {
      controls: true,
      preload: 'metadata',
      src: href,
      width: savedVideoWidth(href) || DEFAULT_VIDEO_WIDTH,
      className: 'max-w-full h-auto',
    });
    paragraph.replaceWith(video);
  });
};

const renderMarkdown = markdown => {
  if (!markdown) return '';
  const html = new MessageFormatter(markdown).formattedMessage;
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const match = markdown.match(COLWIDTHS_RE);
  if (match) applyColumnWidths(doc, match[1].split(',').map(Number));
  applyVideoPreviews(doc);
  return doc.body.innerHTML;
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
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="lg"
    :title="t('HELP_CENTER.EDIT_ARTICLE_PAGE.DIFF_DIALOG.TITLE')"
  >
    <template #header>
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
    </template>

    <div class="flex flex-col gap-4">
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
    </div>
  </SidePanel>
</template>
