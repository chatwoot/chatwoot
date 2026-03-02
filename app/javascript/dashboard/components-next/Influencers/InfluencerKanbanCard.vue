<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import InfluencerProfilesAPI from 'dashboard/api/influencerProfiles';
import FqsScoreBadge from './FqsScoreBadge.vue';

const props = defineProps({
  profile: { type: Object, required: true },
});

const emit = defineEmits(['select', 'retryApify']);

const { t } = useI18n();

const avatarUrl = computed(() => {
  if (props.profile.avatar_url) return props.profile.avatar_url;
  if (props.profile.profile_picture_url) {
    return InfluencerProfilesAPI.proxyImageUrl(
      props.profile.profile_picture_url
    );
  }
  return null;
});

const formatNumber = n => {
  if (n == null) return '—';
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return String(n);
};

const formatER = er => {
  if (er == null) return '—';
  return `${(er * 100).toFixed(2)}%`;
};

const isApifyPending = computed(
  () =>
    props.profile.apify_status === 'apify_pending' ||
    props.profile.apify_status === 'apify_none'
);
const isApifyFailed = computed(
  () => props.profile.apify_status === 'apify_failed'
);
const isApifyDone = computed(() => props.profile.apify_status === 'apify_done');
const showFqs = computed(
  () => props.profile.status !== 'discovered' && props.profile.fqs_score != null
);
const isEnrichmentPending = computed(
  () => props.profile.enrichment_pending === true
);
</script>

<template>
  <div
    class="relative flex flex-col gap-2 p-3 rounded-lg border border-n-weak bg-n-background cursor-pointer hover:bg-n-solid-1 transition-colors"
    @click="emit('select', profile)"
  >
    <!-- Apify pending overlay -->
    <div
      v-if="isApifyPending && profile.status === 'discovered'"
      class="absolute inset-0 z-10 flex items-center justify-center rounded-lg bg-n-background/60"
    >
      <div class="flex items-center gap-2 text-xs text-n-slate-10">
        <span class="i-lucide-loader-2 animate-spin size-4" />
        {{ t('INFLUENCER.KANBAN.APIFY_PENDING') }}
      </div>
    </div>

    <!-- Apify failed banner -->
    <div
      v-if="isApifyFailed && profile.status === 'discovered'"
      class="flex items-center justify-between gap-1 px-2 py-1 text-xs rounded bg-n-amber-2 text-n-amber-11"
    >
      <span class="truncate" :title="profile.apify_error">
        <span class="i-lucide-alert-triangle size-3 mr-1 align-text-bottom" />
        {{ profile.apify_error || t('INFLUENCER.KANBAN.APIFY_FAILED') }}
      </span>
      <button
        class="flex-shrink-0 flex items-center gap-1 px-1.5 py-0.5 rounded font-medium hover:bg-n-amber-3"
        @click.stop="emit('retryApify', profile.id)"
      >
        <span class="i-lucide-refresh-cw size-3" />
        {{ t('INFLUENCER.KANBAN.RETRY') }}
      </button>
    </div>

    <!-- IC enrichment pending indicator -->
    <div
      v-if="isEnrichmentPending"
      class="absolute top-2 right-2 z-10 flex items-center gap-1 px-2 py-0.5 text-xs rounded bg-n-blue-2 text-n-blue-11"
    >
      <span class="i-lucide-loader-2 animate-spin size-3" />
      {{ t('INFLUENCER.KANBAN.ENRICHING') }}
    </div>

    <!-- Profile header -->
    <div class="flex items-center gap-2">
      <img
        v-if="avatarUrl"
        :src="avatarUrl"
        class="size-8 rounded-full object-cover flex-shrink-0"
        loading="lazy"
        @error="$event.target.style.display = 'none'"
      />
      <div
        v-else
        class="size-8 rounded-full bg-n-solid-3 flex items-center justify-center flex-shrink-0"
      >
        <span class="i-lucide-user size-4 text-n-slate-10" />
      </div>
      <div class="flex flex-col min-w-0">
        <span class="text-sm font-medium text-n-slate-12 truncate">
          {{ profile.fullname || profile.username }}
        </span>
        <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
        <span class="text-xs text-n-slate-10 truncate">
          @{{ profile.username }}
        </span>
      </div>
    </div>

    <!-- Bio excerpt (only if apify done) -->
    <p
      v-if="isApifyDone && profile.bio"
      class="text-xs text-n-slate-10 line-clamp-2"
    >
      {{ profile.bio }}
    </p>

    <!-- Metrics row -->
    <div class="flex items-center gap-3 text-xs text-n-slate-11">
      <span :title="t('INFLUENCER.DETAIL.FOLLOWERS')">
        <span class="i-lucide-users size-3 mr-0.5" />
        {{ formatNumber(profile.followers_count) }}
      </span>
      <span :title="t('INFLUENCER.DETAIL.ER')">
        <span class="i-lucide-heart size-3 mr-0.5" />
        {{ formatER(profile.engagement_rate) }}
      </span>
      <span
        v-if="profile.avg_reel_views"
        :title="t('INFLUENCER.DETAIL.AVG_REEL_VIEWS')"
      >
        <span class="i-lucide-play size-3 mr-0.5" />
        {{ formatNumber(profile.avg_reel_views) }}
      </span>
      <FqsScoreBadge
        v-if="showFqs"
        :score="profile.fqs_score"
        class="ml-auto"
      />
    </div>

    <!-- Rejection reason (rejected column) -->
    <div
      v-if="profile.status === 'rejected' && profile.rejection_reason"
      class="text-xs text-n-ruby-11 bg-n-ruby-2 px-2 py-1 rounded truncate"
      :title="profile.rejection_reason"
    >
      {{ profile.rejection_reason }}
    </div>
  </div>
</template>
