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

onMounted(() => {
  store.dispatch('influencerProfiles/get', { filters: { status: 'rejected' } });
});

const hasProfiles = computed(() => profiles.value.length > 0);
const emptyValue = '-';

function formatHandle(username) {
  return `@${username}`;
}

async function handleRecalculate(profile) {
  try {
    await store.dispatch('influencerProfiles/recalculate', { id: profile.id });
    useAlert(t('INFLUENCER.REJECTED.RECALCULATE_QUEUED'));
  } catch {
    useAlert(t('INFLUENCER.REJECTED.ERROR'));
  }
}
</script>

<template>
  <div class="p-4">
    <div
      v-if="uiFlags.isFetching && !hasProfiles"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ t('INFLUENCER.REJECTED.LOADING') }}
    </div>

    <div
      v-else-if="!hasProfiles"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ t('INFLUENCER.REJECTED.EMPTY') }}
    </div>

    <table v-else class="w-full text-sm">
      <thead>
        <tr class="border-b border-n-weak text-left text-xs text-n-slate-11">
          <th class="px-3 py-2">{{ t('INFLUENCER.REJECTED.PROFILE') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REJECTED.FQS') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REJECTED.REASON') }}</th>
          <th class="px-3 py-2">{{ t('INFLUENCER.REJECTED.ACTIONS') }}</th>
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
          <td class="px-3 py-2">
            <FqsScoreBadge :score="profile.fqs_score || 0" />
          </td>
          <td class="px-3 py-2 text-xs text-n-slate-11">
            {{ profile.rejection_reason || emptyValue }}
          </td>
          <td class="px-3 py-2" @click.stop>
            <button
              class="rounded px-2 py-1 text-xs text-n-brand hover:bg-n-brand/10"
              @click="handleRecalculate(profile)"
            >
              {{ t('INFLUENCER.REJECTED.RECALCULATE') }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
