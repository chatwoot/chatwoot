<script setup>
/* eslint-disable no-use-before-define, no-shadow */
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import FqsScoreBadge from './FqsScoreBadge.vue';
import VoucherCalculator from './VoucherCalculator.vue';
import InfluencerReelPreview from './InfluencerReelPreview.vue';
import InfluencerPostPreview from './InfluencerPostPreview.vue';

const props = defineProps({
  profile: { type: Object, required: true },
});

const emit = defineEmits(['close', 'approve', 'reject', 'requestReport']);
const { t } = useI18n();
const rejectReason = ref('');

const isEnriched = computed(
  () =>
    props.profile.status !== 'discovered' && !!props.profile.report_fetched_at
);
const isImported = computed(() => !!props.profile.id);
const isDiscovered = computed(() => props.profile.status === 'discovered');
const showFqs = computed(
  () => isEnriched.value && props.profile.fqs_score != null
);

const breakdown = computed(() => props.profile.fqs_breakdown || {});

// Warnings from hard filter checks
const warnings = computed(() => {
  const hf = props.profile.fqs_hard_filter_results || {};
  return hf.warnings || [];
});

// Audience types breakdown
const audienceTypes = computed(() => {
  const types = props.profile.audience_types;
  if (!Array.isArray(types) || !types.length) return [];
  return types
    .map(item => ({
      code: item.code || 'unknown',
      weight: Number(item.weight || 0),
    }))
    .sort((a, b) => b.weight - a.weight);
});

// Niche classes from profile interests
const nicheClasses = computed(() => {
  const interests = props.profile.interests;
  if (!Array.isArray(interests)) return [];
  return interests.map(i => i.name).filter(Boolean);
});

// Top hashtags
const topHashtags = computed(() => {
  const tags = props.profile.top_hashtags;
  if (!Array.isArray(tags)) return [];
  return tags
    .slice(0, 10)
    .map(h => (typeof h === 'string' ? h : h.tag || h.name))
    .filter(Boolean);
});

// Niche matcher details
const nicheDetails = computed(() => props.profile.niche_details);

// Top audience interests (sorted by weight)
const topAudienceInterests = computed(() => {
  const interests = props.profile.audience_interests;
  if (!Array.isArray(interests)) return [];
  return [...interests]
    .sort((a, b) => (b.weight || 0) - (a.weight || 0))
    .slice(0, 10);
});

// Niche match sets for green highlighting
const matchedNicheClasses = computed(() => {
  const details = nicheDetails.value;
  if (!details?.from_niche_class?.length) return new Set();
  // Map matched niche categories back to API class names
  const categoryToClass = {
    home: 'Home & DIY',
    photography: 'Film & Photography',
  };
  return new Set(
    details.from_niche_class.map(c => categoryToClass[c]).filter(Boolean)
  );
});

const NICHE_HASHTAG_KEYWORDS = new Set([
  'interior',
  'homedecor',
  'homedesign',
  'wnetrza',
  'einrichtung',
  'decoration',
  'gallerywall',
  'familylife',
  'familienleben',
  'rodzina',
  'photography',
  'diy',
  'crafts',
  'handmade',
  'renovation',
  'furniture',
  'livingroom',
  'bedroom',
]);

const TARGET_INTEREST_IDS = new Set([1560, 190, 36, 11, 1708, 291, 43]);

function isNicheMatch(className) {
  return matchedNicheClasses.value.has(className);
}

function isHashtagMatch(tag) {
  return NICHE_HASHTAG_KEYWORDS.has(tag.toLowerCase());
}

function isInterestMatch(id) {
  return TARGET_INTEREST_IDS.has(Number(id));
}

// FQS factor components
const fqsFactors = computed(() => {
  if (!isEnriched.value) return [];
  return [
    {
      label: 'Engagement',
      value: breakdown.value.engagement_factor,
      detail: `ER ${formatPct(breakdown.value.engagement_rate)} · Views ${formatNumber(breakdown.value.median_reel_views)} / ${formatNumber(breakdown.value.followers_count)}`,
    },
    {
      label: t('INFLUENCER.DETAIL.FQS_GEO_FACTOR'),
      value: breakdown.value.geo_factor,
      detail: `EU ${formatCountryPct(breakdown.value.eu_audience_ratio * 100)}`,
    },
    {
      label: t('INFLUENCER.DETAIL.FQS_AQ_FACTOR'),
      value: breakdown.value.aq_factor,
      detail: `Credibility ${formatCountryPct(breakdown.value.audience_credibility * 100)}`,
    },
    {
      label: t('INFLUENCER.DETAIL.FQS_AF_FACTOR'),
      value: breakdown.value.af_factor,
      detail: `Score ${breakdown.value.af_score?.toFixed(1) || '-'}`,
    },
  ];
});

// --- Audience Geo ---
const EUROPE_COUNTRY_CODES = new Set([
  'AD',
  'AL',
  'AM',
  'AT',
  'AZ',
  'BA',
  'BE',
  'BG',
  'BY',
  'CH',
  'CY',
  'CZ',
  'DE',
  'DK',
  'EE',
  'ES',
  'FI',
  'FR',
  'GB',
  'GE',
  'GR',
  'HR',
  'HU',
  'IE',
  'IS',
  'IT',
  'LI',
  'LT',
  'LU',
  'LV',
  'MC',
  'MD',
  'ME',
  'MK',
  'MT',
  'NL',
  'NO',
  'PL',
  'PT',
  'RO',
  'RS',
  'RU',
  'SE',
  'SI',
  'SK',
  'SM',
  'TR',
  'UA',
  'VA',
  'XK',
]);

// Generate a color that smoothly lightens with each step
function gradientColor(index, count, darkHsl, lightHsl) {
  const t = count <= 1 ? 0 : index / (count - 1);
  const h = darkHsl[0] + (lightHsl[0] - darkHsl[0]) * t;
  const s = darkHsl[1] + (lightHsl[1] - darkHsl[1]) * t;
  const l = darkHsl[2] + (lightHsl[2] - darkHsl[2]) * t;
  return `hsl(${Math.round(h)}, ${Math.round(s)}%, ${Math.round(l)}%)`;
}

const geoCountries = computed(() => {
  const countries = props.profile.audience_geo?.countries;
  if (!Array.isArray(countries)) return [];

  const all = countries
    .filter(c => c.weight > 0)
    .map(c => {
      const code = String(c.code || '').toUpperCase();
      return {
        code,
        name: c.name || code,
        weight: Number(c.weight || 0),
        isEu: EUROPE_COUNTRY_CODES.has(code),
      };
    });

  const eu = all.filter(c => c.isEu).sort((a, b) => b.weight - a.weight);
  const nonEu = all.filter(c => !c.isEu).sort((a, b) => b.weight - a.weight);

  const EU_LABEL_LIMIT = 5;
  const NON_EU_LABEL_LIMIT = 3;

  // Green gradient for top EU countries [h, s%, l%]
  const euDark = [142, 71, 32];
  const euLight = [142, 55, 55];
  // Gray gradient for non-EU countries
  const grayDark = [215, 16, 42];
  const grayLight = [215, 12, 60];

  // Overflow EU countries become the next gray shades after labeled non-EU
  const totalGrayCount = NON_EU_LABEL_LIMIT + eu.length - EU_LABEL_LIMIT;
  const overflowGrayStart = NON_EU_LABEL_LIMIT; // continue gray gradient after labeled non-EU

  const result = [];
  eu.forEach((c, i) => {
    if (i < EU_LABEL_LIMIT) {
      result.push({
        ...c,
        showLabel: true,
        color: gradientColor(i, EU_LABEL_LIMIT, euDark, euLight),
      });
    } else {
      // Overflow EU → gray, continuing from where labeled non-EU left off
      const grayIdx = overflowGrayStart + (i - EU_LABEL_LIMIT);
      result.push({
        ...c,
        showLabel: false,
        color: gradientColor(
          grayIdx,
          Math.max(totalGrayCount, grayIdx + 1),
          grayDark,
          grayLight
        ),
      });
    }
  });
  nonEu.forEach((c, i) => {
    result.push({
      ...c,
      showLabel: i < NON_EU_LABEL_LIMIT,
      color: gradientColor(
        i,
        Math.max(nonEu.length, totalGrayCount),
        grayDark,
        grayLight
      ),
    });
  });
  return result;
});

const audienceEuPct = computed(() => {
  return (
    geoCountries.value
      .filter(c => c.isEu)
      .reduce((sum, c) => sum + c.weight, 0) * 100
  );
});

const calculatedEngagementRate = computed(() => {
  const followers = Number(props.profile.followers_count || 0);
  if (!followers) return null;

  const avgLikes = Number(props.profile.avg_likes || 0);
  const avgComments = Number(props.profile.avg_comments || 0);
  return (avgLikes + avgComments) / followers;
});

// Raw data
const rawDataFields = computed(() => {
  const p = props.profile;
  const fields = [
    { label: 'Username', value: p.username },
    { label: 'Full Name', value: p.fullname },
    { label: 'Platform', value: p.platform },
    { label: 'Followers', value: p.followers_count },
    { label: 'Following', value: p.following_count },
    { label: 'Engagement Rate', value: p.engagement_rate, format: 'pct' },
    { label: 'Avg Likes', value: p.avg_likes, format: 'number' },
    { label: 'Avg Comments', value: p.avg_comments, format: 'number' },
    { label: 'Avg Reel Views', value: p.avg_reel_views, format: 'number' },
    {
      label: 'Median Reel Views',
      value: p.median_reel_views,
      format: 'number',
    },
    {
      label: 'Audience Credibility',
      value: p.audience_credibility,
      format: 'pct',
    },
    { label: 'Target Market', value: p.target_market },
    { label: 'Verified', value: p.is_verified },
    { label: 'Bio', value: p.bio },
    { label: 'Status', value: p.status },
    { label: 'FQS Score', value: p.fqs_score },
    { label: 'FQS Breakdown', value: p.fqs_breakdown, format: 'json' },
    { label: 'Report Fetched', value: p.report_fetched_at },
    { label: 'Contact ID', value: p.contact_id },
    {
      label: 'Recent Reels',
      value: p.recent_reels?.length ? `${p.recent_reels.length} reels` : null,
    },
    { label: 'Rejection Reason', value: p.rejection_reason },
    { label: 'Created', value: p.created_at },
    { label: 'Updated', value: p.updated_at },
  ];
  return fields.filter(
    f => f.value != null && f.value !== '' && f.value !== false
  );
});

function formatRawValue(field) {
  if (field.format === 'pct') return `${(field.value * 100).toFixed(2)}%`;
  if (field.format === 'number') return formatNumber(field.value);
  if (field.format === 'json') return JSON.stringify(field.value, null, 0);
  if (field.value === true) return 'Yes';
  return String(field.value);
}

function formatNumber(n) {
  if (!n) return '-';
  if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
  return String(Math.round(n));
}

function formatPct(val) {
  if (!val && val !== 0) return '-';
  return `${(val * 100).toFixed(1)}%`;
}

function formatCountryPct(val) {
  if (val == null) return '-';
  return `${val.toFixed(1)}%`;
}

function factorColor(value) {
  if (value >= 1.0) return 'text-green-700';
  if (value >= 0.5) return 'text-yellow-700';
  return 'text-red-700';
}

function audienceTypeLabel(code) {
  const labels = {
    real: 'Real People',
    mass_followers: 'Mass Followers',
    suspicious: 'Suspicious',
    influencers: 'Influencers',
  };
  return labels[code] || code;
}

function audienceTypeColor(code) {
  if (code === 'real') return 'bg-green-500';
  if (code === 'mass_followers') return 'bg-red-500';
  if (code === 'suspicious') return 'bg-yellow-500';
  return 'bg-n-slate-8';
}

function handleReject() {
  emit('reject', props.profile.id, rejectReason.value);
}
</script>

<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<template>
  <div
    class="fixed inset-y-0 right-0 z-50 flex w-full max-w-lg flex-col bg-n-solid-1 shadow-xl"
  >
    <div
      class="flex items-center justify-between border-b border-n-weak px-6 py-4"
    >
      <div class="flex items-center gap-2">
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.TITLE') }}
        </h2>
        <span
          v-if="isEnriched"
          class="rounded-md bg-n-green/20 px-2 py-0.5 text-xs font-medium text-green-700"
        >
          {{ t('INFLUENCER.DETAIL.ENRICHED') }}
        </span>
        <span
          v-else-if="isImported"
          class="rounded-md bg-n-yellow/20 px-2 py-0.5 text-xs font-medium text-yellow-700"
        >
          {{ t('INFLUENCER.DETAIL.IMPORTED') }}
        </span>
        <span
          v-else
          class="rounded-md bg-n-slate-3 px-2 py-0.5 text-xs font-medium text-n-slate-11"
        >
          {{ t('INFLUENCER.DETAIL.DISCOVERY') }}
        </span>
      </div>
      <button
        class="rounded-md p-1 text-n-slate-11 hover:bg-n-background"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-5" />
      </button>
    </div>

    <div class="flex-1 overflow-auto p-6">
      <!-- Warnings banner -->
      <div v-if="warnings.length" class="mb-4 space-y-1">
        <div
          v-for="(warning, idx) in warnings"
          :key="idx"
          class="flex items-start gap-2 rounded-lg bg-n-yellow/10 px-3 py-2"
        >
          <span
            class="i-lucide-alert-triangle mt-0.5 size-3.5 shrink-0 text-yellow-600"
          />
          <span class="text-xs text-yellow-800">{{ warning }}</span>
        </div>
      </div>

      <!-- Profile header -->
      <div class="mb-6 flex items-center gap-4">
        <img
          v-if="profile.avatar_url || profile.profile_picture_url"
          :src="profile.avatar_url || profile.profile_picture_url"
          :alt="profile.username"
          class="size-16 rounded-full object-cover"
        />
        <div>
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ profile.fullname || profile.username }}
            </h3>
            <span
              v-if="profile.is_verified"
              class="i-lucide-badge-check text-n-brand"
            />
          </div>
          <p class="text-sm text-n-slate-11">@{{ profile.username }}</p>
          <a
            :href="`https://www.instagram.com/${profile.username}/`"
            target="_blank"
            rel="noopener noreferrer"
            class="text-xs text-n-brand hover:underline"
          >
            {{ t('INFLUENCER.DETAIL.VIEW_INSTAGRAM') }}
          </a>
        </div>
      </div>

      <p v-if="profile.bio" class="mb-4 text-sm text-n-slate-11">
        {{ profile.bio }}
      </p>

      <!-- FQS Score (only for enriched+) -->
      <FqsScoreBadge
        v-if="showFqs"
        :score="profile.fqs_score"
        :breakdown="profile.fqs_breakdown"
        class="mb-4"
      />

      <!-- Key metrics -->
      <div class="mb-6 grid grid-cols-2 gap-4">
        <div class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.FOLLOWERS') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatNumber(profile.followers_count) }}
          </p>
        </div>
        <div class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.ER') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatPct(profile.engagement_rate) }}
          </p>
          <p class="text-[11px] text-n-slate-10">
            {{ t('INFLUENCER.DETAIL.ER_CALCULATED') }}:
            {{ formatPct(calculatedEngagementRate) }}
          </p>
        </div>
        <div class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.AVG_LIKES') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatNumber(profile.avg_likes) }}
          </p>
        </div>
        <div class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.AVG_COMMENTS') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatNumber(profile.avg_comments) }}
          </p>
        </div>
        <div v-if="isEnriched" class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.MEDIAN_VIEWS') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{
              formatNumber(profile.median_reel_views || profile.avg_reel_views)
            }}
          </p>
          <p
            v-if="profile.median_reel_views && profile.avg_reel_views"
            class="text-[11px] text-n-slate-10"
          >
            avg: {{ formatNumber(profile.avg_reel_views) }}
          </p>
        </div>
        <div v-if="isEnriched" class="rounded-lg bg-n-background p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('INFLUENCER.DETAIL.CREDIBILITY') }}
          </p>
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatPct(profile.audience_credibility) }}
          </p>
        </div>
      </div>

      <!-- FQS Formula breakdown -->
      <div v-if="isEnriched && fqsFactors.length" class="mb-6">
        <div class="mb-2">
          <p class="font-mono text-xs text-n-slate-11">
            FQS = √(ER × Views) × Geo × AQ × AF × 100
          </p>
        </div>
        <div class="space-y-2">
          <div
            v-for="factor in fqsFactors"
            :key="factor.label"
            class="flex items-center gap-2 rounded-lg bg-n-background px-3 py-2"
          >
            <div class="w-24 text-xs text-n-slate-11">{{ factor.label }}</div>
            <div class="flex-1 text-xs text-n-slate-10">
              {{ factor.detail }}
            </div>
            <div
              class="text-sm font-semibold"
              :class="factorColor(factor.value)"
            >
              ×{{ factor.value?.toFixed(2) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Voucher Calculator -->
      <VoucherCalculator :profile="profile" class="mb-6" />

      <!-- Audience Types breakdown -->
      <div v-if="isEnriched && audienceTypes.length" class="mb-6">
        <h4 class="mb-3 text-sm font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.AUDIENCE_TYPES_TITLE') }}
        </h4>
        <div class="mb-2 flex h-4 overflow-hidden rounded-full">
          <div
            v-for="at in audienceTypes"
            :key="at.code"
            :class="audienceTypeColor(at.code)"
            :style="{ width: `${at.weight * 100}%` }"
            :title="`${audienceTypeLabel(at.code)}: ${(at.weight * 100).toFixed(1)}%`"
          />
        </div>
        <div class="flex flex-wrap gap-3 text-xs">
          <div
            v-for="at in audienceTypes"
            :key="at.code"
            class="flex items-center gap-1.5"
          >
            <span
              class="inline-block size-2.5 rounded-full"
              :class="audienceTypeColor(at.code)"
            />
            <span class="text-n-slate-11">{{
              audienceTypeLabel(at.code)
            }}</span>
            <span class="font-semibold text-n-slate-12">
              {{ (at.weight * 100).toFixed(1) }}%
            </span>
          </div>
        </div>
      </div>

      <!-- Audience Geo (country stacked bar) -->
      <div v-if="isEnriched && geoCountries.length" class="mb-6">
        <div class="mb-3 flex items-center justify-between">
          <h4 class="text-sm font-semibold text-n-slate-12">
            {{ t('INFLUENCER.DETAIL.AUDIENCE_GEO_TITLE') }}
          </h4>
          <span class="text-xs text-n-slate-11">
            EU {{ formatCountryPct(audienceEuPct) }}
          </span>
        </div>
        <!-- Stacked bar -->
        <div class="mb-2 flex h-4 overflow-hidden rounded-full bg-n-slate-3">
          <div
            v-for="country in geoCountries"
            :key="country.code"
            :style="{
              width: `${country.weight * 100}%`,
              backgroundColor: country.color,
            }"
            :title="`${country.name}: ${(country.weight * 100).toFixed(1)}%`"
          />
        </div>
        <!-- Legend -->
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
          <div
            v-for="country in geoCountries.filter(c => c.showLabel)"
            :key="country.code"
            class="flex items-center gap-1.5"
          >
            <span
              class="inline-block size-2.5 rounded-full"
              :style="{ backgroundColor: country.color }"
            />
            <span class="text-n-slate-11">{{ country.name }}</span>
            <span class="font-semibold text-n-slate-12">
              {{ (country.weight * 100).toFixed(1) }}%
            </span>
          </div>
        </div>
      </div>

      <!-- Recent reels -->
      <div v-if="profile.recent_reels?.length" class="mb-6">
        <h4 class="mb-2 text-sm font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.RECENT_REELS') }}
        </h4>
        <div class="grid grid-cols-3 gap-2">
          <InfluencerReelPreview
            v-for="(reel, idx) in profile.recent_reels.slice(0, 6)"
            :key="idx"
            :reel="reel"
          />
        </div>
      </div>

      <!-- Recent posts -->
      <div v-if="profile.recent_posts?.length" class="mb-6">
        <h4 class="mb-2 text-sm font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.RECENT_POSTS') }}
        </h4>
        <div class="grid grid-cols-3 gap-2">
          <InfluencerPostPreview
            v-for="(post, idx) in profile.recent_posts.slice(0, 6)"
            :key="idx"
            :post="post"
          />
        </div>
      </div>

      <!-- Niche & Content -->
      <div
        v-if="
          isEnriched &&
          (nicheClasses.length ||
            topHashtags.length ||
            topAudienceInterests.length)
        "
        class="mb-6"
      >
        <h4 class="mb-3 text-sm font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.NICHE_TITLE') }}
        </h4>

        <!-- Content categories -->
        <div v-if="nicheClasses.length" class="mb-3">
          <p class="mb-1 text-xs text-n-slate-11">Content categories</p>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="niche in nicheClasses"
              :key="niche"
              class="rounded-md px-2 py-0.5 text-xs"
              :class="
                isNicheMatch(niche)
                  ? 'bg-green-100 text-n-slate-12'
                  : 'bg-n-slate-3 text-n-slate-12'
              "
            >
              {{ niche }}
            </span>
          </div>
        </div>

        <!-- Top hashtags -->
        <div v-if="topHashtags.length" class="mb-3">
          <p class="mb-1 text-xs text-n-slate-11">Top hashtags</p>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="tag in topHashtags"
              :key="tag"
              class="rounded-md px-2 py-0.5 text-xs"
              :class="
                isHashtagMatch(tag)
                  ? 'bg-green-100 text-n-slate-12'
                  : 'bg-n-slate-3 text-n-slate-12'
              "
            >
              #{{ tag }}
            </span>
          </div>
        </div>

        <!-- Top audience interests -->
        <div v-if="topAudienceInterests.length" class="mb-3">
          <p class="mb-1 text-xs text-n-slate-11">Top audience interests</p>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="interest in topAudienceInterests"
              :key="interest.id"
              class="rounded-md px-2 py-0.5 text-xs"
              :class="
                isInterestMatch(interest.id)
                  ? 'bg-green-100 text-n-slate-12'
                  : 'bg-n-slate-3 text-n-slate-12'
              "
            >
              {{ interest.name }}
              <span class="text-[10px] opacity-60">
                {{ (interest.weight * 100).toFixed(0) }}%
              </span>
              <span v-if="interest.affinity" class="text-[10px] opacity-40">
                {{ interest.affinity.toFixed(1) }}x
              </span>
            </span>
          </div>
        </div>
      </div>

      <!-- Not enriched hint (discovered profiles) -->
      <div
        v-if="isDiscovered && isImported"
        class="mb-6 rounded-lg bg-n-blue/10 p-3"
      >
        <p class="text-xs text-n-blue-11">
          {{ t('INFLUENCER.DETAIL.ENRICH_HINT') }}
        </p>
      </div>

      <div
        v-if="profile.rejection_reason"
        class="mb-6 rounded-lg bg-n-ruby/10 p-3"
      >
        <p class="text-xs font-medium text-red-700">
          {{ t('INFLUENCER.DETAIL.REJECTION_REASON') }}:
          {{ profile.rejection_reason }}
        </p>
      </div>

      <!-- Raw data from DB -->
      <div class="mb-6">
        <h4 class="mb-3 text-sm font-semibold text-n-slate-12">
          {{ t('INFLUENCER.DETAIL.RAW_DATA') }}
        </h4>
        <div class="rounded-lg border border-n-weak">
          <div
            v-for="(field, idx) in rawDataFields"
            :key="field.label"
            class="flex items-start gap-2 px-3 py-1.5 text-xs"
            :class="{ 'border-t border-n-weak/50': idx > 0 }"
          >
            <span class="w-32 shrink-0 text-n-slate-11">{{ field.label }}</span>
            <span
              class="min-w-0 break-all text-n-slate-12"
              :class="{ 'font-mono text-[11px]': field.format === 'json' }"
            >
              {{ formatRawValue(field) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions for enriched profiles -->
    <div
      v-if="profile.status === 'enriched'"
      class="border-t border-n-weak p-4"
    >
      <div class="mb-3">
        <input
          v-model="rejectReason"
          type="text"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.DETAIL.REJECT_REASON_PLACEHOLDER')"
        />
      </div>
      <div class="flex gap-2">
        <button
          class="flex-1 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
          @click="emit('approve', profile.id)"
        >
          {{ t('INFLUENCER.DETAIL.APPROVE') }}
        </button>
        <button
          class="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
          @click="handleReject"
        >
          {{ t('INFLUENCER.DETAIL.REJECT') }}
        </button>
      </div>
    </div>

    <!-- Actions for discovered profiles -->
    <div
      v-else-if="profile.status === 'discovered'"
      class="border-t border-n-weak p-4"
    >
      <div class="mb-3">
        <input
          v-model="rejectReason"
          type="text"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.DETAIL.REJECT_REASON_PLACEHOLDER')"
        />
      </div>
      <div class="flex gap-2">
        <button
          class="flex-1 rounded-lg bg-n-brand px-4 py-2 text-sm font-medium text-white hover:opacity-90"
          @click="emit('requestReport', profile.id)"
        >
          {{ t('INFLUENCER.REVIEW.FETCH_REPORT') }}
        </button>
        <button
          class="flex-1 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
          @click="handleReject"
        >
          {{ t('INFLUENCER.DETAIL.REJECT') }}
        </button>
      </div>
    </div>
  </div>
</template>
