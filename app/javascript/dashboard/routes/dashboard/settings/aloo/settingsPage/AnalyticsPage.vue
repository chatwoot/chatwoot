<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import AlooAssistantAPI from 'dashboard/api/aloo/assistant';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const isLoading = ref(true);
const stats = ref({
  total_conversations: 0,
  total_messages: 0,
  total_tokens: 0,
  total_documents: 0,
});
const performance = ref({
  response_rate: null,
  avg_response_time_ms: null,
  handoff_rate: null,
  token_usage: { total_input: 0, total_output: 0, total: 0 },
});
const timeRange = ref('7d');
const conversations = computed(
  () => getters['alooConversations/getRecords'].value
);
const conversationsMeta = computed(
  () => getters['alooConversations/getMeta'].value || {}
);

const fetchData = async () => {
  isLoading.value = true;
  try {
    const [statsResponse, performanceResponse] = await Promise.all([
      AlooAssistantAPI.getStats(props.assistantId),
      AlooAssistantAPI.getPerformance(props.assistantId, timeRange.value),
      store.dispatch('alooConversations/getConversations', {
        assistantId: props.assistantId,
      }),
    ]);
    stats.value = statsResponse.data;
    performance.value = performanceResponse.data;
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(async () => {
  await fetchData();
});

const changeTimeRange = async range => {
  timeRange.value = range;
  try {
    const response = await AlooAssistantAPI.getPerformance(
      props.assistantId,
      range
    );
    performance.value = response.data;
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const openConversation = conversationId => {
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: conversationId,
    })
  );
};

const formatDuration = ms => {
  if (ms === null || ms === undefined) return '-';
  if (!ms) return '0s';
  if (ms < 1000) return `${Math.round(ms)}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
};

const formatNumber = num => {
  if (!num) return '0';
  if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`;
  if (num >= 1000) return `${(num / 1000).toFixed(1)}K`;
  return num.toString();
};

const formatDate = dateStr => {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString();
};

const timeRangeOptions = [
  { value: '24h', label: '24h' },
  { value: '7d', label: '7 days' },
  { value: '30d', label: '30 days' },
  { value: '90d', label: '90 days' },
];
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('ALOO.ANALYTICS.LOADING')" />
    </div>

    <template v-else>
      <!-- Stats Overview -->
      <SettingsSection
        :title="$t('ALOO.ANALYTICS.OVERVIEW.TITLE')"
        :sub-title="$t('ALOO.ANALYTICS.OVERVIEW.DESCRIPTION')"
      >
        <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-slate-12">
              {{ formatNumber(stats.total_conversations) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.STATS.CONVERSATIONS') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-slate-12">
              {{ formatNumber(stats.total_messages) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.STATS.MESSAGES') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-slate-12">
              {{ formatNumber(stats.total_tokens) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.STATS.TOKENS') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-slate-12">
              {{ formatNumber(stats.total_documents) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.STATS.DOCUMENTS') }}
            </p>
          </div>
        </div>
      </SettingsSection>

      <!-- Performance Metrics -->
      <SettingsSection
        :title="$t('ALOO.ANALYTICS.PERFORMANCE.TITLE')"
        :sub-title="$t('ALOO.ANALYTICS.PERFORMANCE.DESCRIPTION')"
      >
        <!-- Time Range Selector -->
        <div class="flex gap-2 mb-4">
          <button
            v-for="option in timeRangeOptions"
            :key="option.value"
            class="px-3 py-1.5 rounded-lg text-sm font-medium transition-colors"
            :class="
              timeRange === option.value
                ? 'bg-n-blue-9 text-white'
                : 'bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3'
            "
            @click="changeTimeRange(option.value)"
          >
            {{ option.label }}
          </button>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-green-11">
              {{
                performance.response_rate !== null
                  ? `${performance.response_rate}%`
                  : '-'
              }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.PERFORMANCE.RESPONSE_RATE') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-blue-11">
              {{ formatDuration(performance.avg_response_time_ms) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.PERFORMANCE.AVG_RESPONSE_TIME') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-amber-11">
              {{
                performance.handoff_rate !== null
                  ? `${performance.handoff_rate}%`
                  : '-'
              }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.PERFORMANCE.HANDOFF_RATE') }}
            </p>
          </div>
          <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
            <p class="text-2xl font-semibold text-n-slate-12">
              {{ formatNumber(performance.token_usage?.total || 0) }}
            </p>
            <p class="text-sm text-n-slate-10">
              {{ $t('ALOO.ANALYTICS.PERFORMANCE.TOKENS_USED') }}
            </p>
          </div>
        </div>
      </SettingsSection>

      <!-- Recent Conversations -->
      <SettingsSection
        :title="$t('ALOO.ANALYTICS.CONVERSATIONS.TITLE')"
        :sub-title="$t('ALOO.ANALYTICS.CONVERSATIONS.DESCRIPTION')"
        :show-border="false"
      >
        <div v-if="conversations.length" class="space-y-2">
          <div
            v-for="conv in conversations"
            :key="conv.id"
            class="flex items-center justify-between p-4 bg-n-alpha-1 rounded-lg border border-n-weak hover:bg-n-alpha-2 cursor-pointer transition-colors"
            @click="openConversation(conv.conversation_id)"
          >
            <div class="flex items-center gap-3">
              <div
                class="flex items-center justify-center w-10 h-10 rounded-full bg-n-alpha-3"
              >
                <span class="i-lucide-user text-lg text-n-slate-11" />
              </div>
              <div>
                <p class="text-sm font-medium text-n-slate-12">
                  {{ conv.contact_name }}
                </p>
                <p class="text-xs text-n-slate-10">
                  {{
                    conv.contact_email ||
                    $t('ALOO.ANALYTICS.CONVERSATIONS.NO_EMAIL')
                  }}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-6 text-sm text-n-slate-10">
              <span>
                {{ conv.message_count }}
                {{ $t('ALOO.ANALYTICS.CONVERSATIONS.MESSAGES') }}
              </span>
              <span>
                {{ formatNumber(conv.total_tokens) }}
                {{ $t('ALOO.ANALYTICS.CONVERSATIONS.TOKENS') }}
              </span>
              <span>{{ formatDate(conv.updated_at) }}</span>
              <span class="i-lucide-chevron-right text-lg" />
            </div>
          </div>

          <!-- Pagination -->
          <div
            v-if="conversationsMeta.total_pages > 1"
            class="flex items-center justify-center gap-2 pt-4"
          >
            <span class="text-sm text-n-slate-11">
              {{
                $t('ALOO.ANALYTICS.CONVERSATIONS.SHOWING', {
                  count: conversations.length,
                  total: conversationsMeta.total_count,
                })
              }}
            </span>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-message-square text-3xl text-n-slate-9" />
          <p class="text-sm text-n-slate-11 mt-2">
            {{ $t('ALOO.ANALYTICS.CONVERSATIONS.EMPTY') }}
          </p>
        </div>
      </SettingsSection>
    </template>
  </div>
</template>
