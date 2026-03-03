<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';

const props = defineProps({
  profile: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const offers = ref([]);
const loading = ref(false);
const creating = ref(false);
const copiedToken = ref(null);

const isAccepted = computed(
  () =>
    props.profile.status === 'accepted' || props.profile.status === 'contacted'
);

const hasActiveOffer = computed(() =>
  offers.value.some(
    o => o.status === 'pending' && new Date(o.expires_at) > new Date()
  )
);

async function fetchOffers() {
  loading.value = true;
  try {
    offers.value = await store.dispatch('influencerProfiles/getOffers', {
      profileId: props.profile.id,
    });
  } catch {
    offers.value = [];
  } finally {
    loading.value = false;
  }
}

const offerError = ref('');

async function handleGenerate() {
  creating.value = true;
  offerError.value = '';
  try {
    await store.dispatch('influencerProfiles/createOffer', {
      profileId: props.profile.id,
      packages: { reel: true, carousel: true, stories: true },
      rightsLevel: 'standard',
      currency: 'EUR',
    });
    await fetchOffers();
  } catch (err) {
    offerError.value =
      err?.response?.data?.error || t('INFLUENCER.OFFERS.CREATE_ERROR');
    await fetchOffers();
  } finally {
    creating.value = false;
  }
}

function copyOfferLink(offer) {
  navigator.clipboard.writeText(offer.offer_url).catch(() => {
    // Fallback: select text from a temporary input
    const input = document.createElement('input');
    input.value = offer.offer_url;
    document.body.appendChild(input);
    input.select();
    document.execCommand('copy');
    document.body.removeChild(input);
  });
  copiedToken.value = offer.token;
  setTimeout(() => {
    copiedToken.value = null;
  }, 2000);
}

function statusColor(status) {
  if (status === 'accepted') return 'bg-green-100 text-green-700';
  if (status === 'expired' || status === 'revoked')
    return 'bg-red-100 text-red-700';
  return 'bg-yellow-100 text-yellow-700';
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString();
}

function reset() {
  offers.value = [];
  offerError.value = '';
  if (isAccepted.value) fetchOffers();
}

onMounted(reset);
watch(() => props.profile.id, reset);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div v-if="isAccepted" class="mb-6">
    <div class="mb-3 flex items-center justify-between">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('INFLUENCER.OFFERS.TITLE') }}
      </h4>
      <button
        class="flex items-center gap-1 rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-violet-700 disabled:opacity-50"
        :disabled="creating || hasActiveOffer"
        :title="
          hasActiveOffer ? t('INFLUENCER.OFFERS.ACTIVE_EXISTS') : undefined
        "
        @click="handleGenerate"
      >
        <span v-if="creating" class="i-lucide-loader-2 size-3 animate-spin" />
        <span v-else class="i-lucide-gift size-3" />
        {{
          creating
            ? t('INFLUENCER.OFFERS.CREATING')
            : t('INFLUENCER.OFFERS.GENERATE')
        }}
      </button>
    </div>

    <p v-if="offerError" class="mb-2 text-xs text-red-600">
      {{ offerError }}
    </p>

    <!-- Offers list -->
    <div v-if="loading" class="py-3 text-center text-xs text-n-slate-10">
      <span
        class="i-lucide-loader-2 mr-1 inline-block size-3 animate-spin align-text-bottom"
      />
      {{ t('INFLUENCER.OFFERS.LOADING') }}
    </div>

    <div v-else-if="offers.length" class="space-y-2">
      <div
        v-for="offer in offers"
        :key="offer.id"
        class="rounded-lg border border-n-weak p-3"
      >
        <div class="flex items-center justify-between">
          <span
            class="rounded-md px-2 py-0.5 text-xs font-medium"
            :class="statusColor(offer.status)"
          >
            {{ offer.status }}
          </span>
          <span class="text-[11px] text-n-slate-10">
            {{ formatDate(offer.created_at) }}
          </span>
        </div>

        <!-- Offer URL -->
        <div class="mt-2 flex items-center gap-2">
          <code
            class="min-w-0 flex-1 truncate rounded bg-n-slate-3 px-2 py-1 text-xs text-n-slate-12"
          >
            {{ offer.offer_url }}
          </code>
          <button
            class="flex flex-shrink-0 items-center gap-1 rounded-lg border border-n-weak px-2 py-1 text-xs text-n-brand hover:bg-n-slate-2"
            @click="copyOfferLink(offer)"
          >
            <span
              :class="
                copiedToken === offer.token ? 'i-lucide-check' : 'i-lucide-copy'
              "
              class="size-3"
            />
            {{
              copiedToken === offer.token
                ? t('INFLUENCER.OFFERS.COPIED')
                : t('INFLUENCER.OFFERS.COPY_LINK')
            }}
          </button>
        </div>

        <div class="mt-2 flex items-center gap-3">
          <span
            v-if="offer.voucher_value"
            class="text-sm font-semibold text-n-slate-12"
          >
            {{ Math.round(offer.voucher_value) }} {{ offer.voucher_currency }}
          </span>
          <span
            v-if="offer.voucher_code"
            class="font-mono text-xs text-n-slate-10"
          >
            {{ offer.voucher_code }}
          </span>
          <span class="text-[11px] text-n-slate-10">
            {{ t('INFLUENCER.OFFERS.EXPIRES') }}
            {{ formatDate(offer.expires_at) }}
          </span>
        </div>
      </div>
    </div>

    <p v-else-if="!loading" class="py-2 text-xs text-n-slate-10">
      {{ t('INFLUENCER.OFFERS.EMPTY') }}
    </p>
  </div>
</template>
