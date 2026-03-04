<script setup>
import { onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import FqsScoreBadge from './FqsScoreBadge.vue';

const emit = defineEmits(['select']);
const store = useStore();
const { t } = useI18n();

const profiles = useMapGetter('influencerProfiles/getInfluencers');
const uiFlags = useMapGetter('influencerProfiles/getUIFlags');
const meta = useMapGetter('influencerProfiles/getMeta');

onMounted(() => {
  store.dispatch('influencerProfiles/get', {
    filters: {},
  });
});

const hasProfiles = computed(() => profiles.value.length > 0);
const emptyValue = '-';

function formatER(er) {
  // ER is stored as decimal ratio (e.g., 0.025 = 2.5%)
  return er ? `${(er * 100).toFixed(2)}%` : '-';
}

function formatNumber(n) {
  if (!n) return '-';
  if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
  return n;
}

const VOUCHER_RATE = 0.019;

function voucherValue(profile) {
  const fqs = profile.fqs_score;
  const followers = Number(profile.followers_count || 0);
  if (fqs == null || !followers) return null;
  return Math.round(followers * (fqs / 100) * VOUCHER_RATE);
}

function formatVoucher(profile) {
  const val = voucherValue(profile);
  if (val == null) return emptyValue;
  return `${val.toLocaleString('pl-PL')} EUR`;
}

function formatHandle(username) {
  return `@${username}`;
}

async function handleApprove(profile) {
  try {
    await store.dispatch('influencerProfiles/approve', { id: profile.id });
    useAlert(t('INFLUENCER.REVIEW.APPROVED'));
  } catch {
    useAlert(t('INFLUENCER.REVIEW.ERROR'));
  }
}

async function handleReject(profile) {
  try {
    await store.dispatch('influencerProfiles/reject', {
      id: profile.id,
      reason: 'Manual rejection',
    });
    useAlert(t('INFLUENCER.REVIEW.REJECTED'));
  } catch {
    useAlert(t('INFLUENCER.REVIEW.ERROR'));
  }
}

async function handleRequestReport(profile) {
  try {
    await store.dispatch('influencerProfiles/requestReport', {
      id: profile.id,
    });
    useAlert(t('INFLUENCER.REVIEW.REPORT_REQUESTED'));
  } catch {
    useAlert(t('INFLUENCER.REVIEW.ERROR'));
  }
}

function loadMore() {
  const nextPage = (meta.value.currentPage || 1) + 1;
  store.dispatch('influencerProfiles/get', {
    page: nextPage,
    filters: {},
  });
}
</script>

<template>
  <div class="p-4">
    <div
      v-if="uiFlags.isFetching && !hasProfiles"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ t('INFLUENCER.REVIEW.LOADING') }}
    </div>

    <div
      v-else-if="!hasProfiles"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ t('INFLUENCER.REVIEW.EMPTY') }}
    </div>

    <table v-else class="w-full text-sm">
      <thead>
        <tr class="border-b border-n-weak text-left text-xs text-n-slate-11">
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.PROFILE') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.FOLLOWERS') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.ER') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.FQS') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.CREDIBILITY') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.VIEWS') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.VOUCHER') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.STATUS') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REVIEW.ACTIONS') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="profile in profiles"
          :key="profile.id"
          class="cursor-pointer border-b border-n-weak/50 transition-colors hover:bg-n-background"
          @click="emit('select', profile)"
        >
          <td class="px-3 py-2">
            <div class="flex items-center gap-2">
              <img
                v-if="profile.avatar_url || profile.profile_picture_url"
                :src="profile.avatar_url || profile.profile_picture_url"
                class="size-8 rounded-full object-cover"
              />
              <div>
                <p class="font-medium text-n-slate-12">
                  {{ profile.fullname || profile.username }}
                </p>
                <p class="text-xs text-n-slate-11">
                  {{ formatHandle(profile.username) }}
                </p>
              </div>
            </div>
          </td>
          <td class="px-3 py-2">{{ formatNumber(profile.followers_count) }}</td>
          <td class="px-3 py-2">{{ formatER(profile.engagement_rate) }}</td>
          <td class="px-3 py-2">
            <FqsScoreBadge
              :score="profile.fqs_score || 0"
              :breakdown="profile.fqs_breakdown"
            />
          </td>
          <td class="px-3 py-2">
            {{
              profile.audience_credibility
                ? `${(profile.audience_credibility * 100).toFixed(0)}%`
                : emptyValue
            }}
          </td>
          <td class="px-3 py-2">{{ formatNumber(profile.avg_reel_views) }}</td>
          <td class="px-3 py-2 font-medium text-n-slate-12">
            {{ formatVoucher(profile) }}
          </td>
          <td class="px-3 py-2">
            <span
              class="rounded-md bg-n-background px-2 py-0.5 text-xs capitalize"
            >
              {{ profile.status?.replace('_', ' ') }}
            </span>
          </td>
          <td class="px-3 py-2" @click.stop>
            <div class="flex gap-1">
              <button
                v-if="profile.status === 'discovered'"
                class="rounded px-2 py-1 text-xs text-n-brand hover:bg-n-brand/10"
                @click="handleRequestReport(profile)"
              >
                {{ t('INFLUENCER.REVIEW.FETCH_REPORT') }}
              </button>
              <button
                v-if="profile.status === 'enriched'"
                class="rounded px-2 py-1 text-xs text-green-600 hover:bg-green-50"
                @click="handleApprove(profile)"
              >
                {{ t('INFLUENCER.REVIEW.APPROVE') }}
              </button>
              <button
                v-if="
                  profile.status !== 'rejected' && profile.status !== 'approved'
                "
                class="rounded px-2 py-1 text-xs text-red-600 hover:bg-red-50"
                @click="handleReject(profile)"
              >
                {{ t('INFLUENCER.REVIEW.REJECT') }}
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="meta.hasMore" class="mt-4 text-center">
      <button
        class="text-sm text-n-brand hover:underline"
        :disabled="uiFlags.isFetching"
        @click="loadMore"
      >
        {{ t('INFLUENCER.REVIEW.LOAD_MORE') }}
      </button>
    </div>
  </div>
</template>
