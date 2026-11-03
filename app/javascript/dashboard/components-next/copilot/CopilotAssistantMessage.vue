<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

import Button from 'dashboard/components-next/button/Button.vue';
import BarChart from 'shared/components/charts/BarChart.vue';

const props = defineProps({
  isLastMessage: {
    type: Boolean,
    default: false,
  },
  message: {
    type: Object,
    required: true,
  },
  canUseReply: {
    type: Boolean,
    default: true,
  },
});

const CONVERSATION_PATH_PATTERN =
  /^\/app\/accounts\/(\d+)\/conversations\/(\d+)$/;

const route = useRoute();
const router = useRouter();
const hasEmptyMessageContent = computed(() => !props.message?.content);

const showUseButton = computed(() => {
  return (
    !hasEmptyMessageContent.value &&
    props.message.reply_suggestion &&
    props.isLastMessage &&
    props.canUseReply
  );
});

// The answer names its charts by the tool call that computed them, and the server attaches that call's charts to
// message.charts, so the panel draws the numbers the tool computed.
const CHART_MARKER_PATTERN = /\[copilot-chart:(\d+)\]/;
const CHART_HEIGHT = 200;

const chartsFor = id =>
  (props.message.charts?.[id] ?? []).map(({ title, categories, series }) => ({
    title,
    data: { categories, series },
  }));

// split keeps the captured tool call IDs at odd indexes, between the markdown before and after each marker. A marker
// without chart data is dropped.
const contentParts = computed(() =>
  props.message.content
    .split(CHART_MARKER_PATTERN)
    .map((part, index) => {
      if (index % 2 === 1) return { charts: chartsFor(part) };
      return { html: new MessageFormatter(part).formattedMessage };
    })
    .filter(part => part.charts?.length || part.html?.trim())
);

const openConversation = event => {
  if (
    event.button ||
    event.ctrlKey ||
    event.metaKey ||
    event.shiftKey ||
    event.altKey
  )
    return;

  const href = event.target.closest('a')?.getAttribute('href');
  const conversation = href?.match(CONVERSATION_PATH_PATTERN);
  if (!conversation || conversation[1] !== String(route.params.accountId))
    return;

  event.preventDefault();
  router.push(href);
};

const useCopilotResponse = () => {
  // Always insert through the rich editor so the markdown is parsed into proper
  // paragraph/hard_break nodes. The plain-text path inserts the reply as a single
  // text node with raw newlines, which the editor collapses into one paragraph as
  // soon as the agent edits the draft.
  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
  useTrack(COPILOT_EVENTS.USE_CAPTAIN_RESPONSE);
};
</script>

<template>
  <div class="flex flex-col gap-1 text-n-slate-12">
    <div class="font-medium">{{ $t('CAPTAIN.NAME') }}</div>
    <span v-if="hasEmptyMessageContent" class="text-n-ruby-11">
      {{ $t('CAPTAIN.COPILOT.EMPTY_MESSAGE') }}
    </span>
    <div v-else class="flex flex-col gap-3">
      <template v-for="(part, index) in contentParts" :key="index">
        <template v-if="part.charts">
          <div v-for="chart in part.charts" :key="chart.title" class="min-w-0">
            <p class="mb-2 text-sm font-medium text-n-slate-11">
              {{ chart.title }}
            </p>
            <BarChart
              :data="chart.data"
              :aria-label="chart.title"
              :height="CHART_HEIGHT"
              show-values
            />
          </div>
        </template>
        <div
          v-else
          v-dompurify-html="part.html"
          class="prose prose-bubble !max-w-none break-words prose-a:text-n-blue-11 prose-a:underline"
          @click="openConversation"
        />
      </template>
    </div>
    <div class="flex flex-row mt-1">
      <Button
        v-if="showUseButton"
        :label="$t('CAPTAIN.COPILOT.USE')"
        faded
        sm
        slate
        @click="useCopilotResponse"
      />
    </div>
  </div>
</template>
