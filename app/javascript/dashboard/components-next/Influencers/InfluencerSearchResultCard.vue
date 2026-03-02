<script setup>
import { computed } from 'vue';
import FqsScoreBadge from './FqsScoreBadge.vue';

const props = defineProps({
  result: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});

const formattedFollowers = computed(() => {
  const count = props.result.followers_count || 0;
  if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
  if (count >= 1000) return `${(count / 1000).toFixed(1)}K`;
  return count;
});

const formattedER = computed(() => {
  const er = props.result.engagement_rate || 0;
  return `${(er * 100).toFixed(2)}%`;
});

const isEnriched = computed(
  () => props.result.status !== 'discovered' && !!props.result.report_fetched_at
);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<template>
  <div
    class="relative cursor-pointer rounded-lg border p-4 transition-colors"
    :class="
      selected
        ? 'border-n-brand bg-n-brand/5'
        : 'border-n-weak bg-n-solid-1 hover:border-n-brand/50'
    "
  >
    <div
      v-if="isEnriched"
      class="absolute right-2 top-2 rounded-md bg-n-green/20 px-2 py-0.5 text-xs font-medium text-green-700"
    >
      Enriched
    </div>

    <div class="mb-3 flex items-center gap-3">
      <img
        v-if="result.avatar_url || result.profile_picture_url"
        :src="result.avatar_url || result.profile_picture_url"
        :alt="result.username"
        class="size-10 rounded-full object-cover"
      />
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-1">
          <p class="truncate text-sm font-semibold text-n-slate-12">
            {{ result.fullname || result.username }}
          </p>
          <span
            v-if="result.is_verified"
            class="i-lucide-badge-check text-n-brand"
          />
        </div>
        <p class="text-xs text-n-slate-11">@{{ result.username }}</p>
      </div>
    </div>

    <div class="flex flex-wrap gap-x-4 gap-y-1 text-xs text-n-slate-11">
      <span>{{ formattedFollowers }} followers</span>
      <span>ER {{ formattedER }}</span>
      <span v-if="result.avg_reel_views">
        {{ Math.round(result.avg_reel_views).toLocaleString() }} avg views
      </span>
    </div>

    <FqsScoreBadge
      v-if="result.fqs_score"
      :score="result.fqs_score"
      :breakdown="result.fqs_breakdown"
      class="mt-2"
    />
  </div>
</template>
