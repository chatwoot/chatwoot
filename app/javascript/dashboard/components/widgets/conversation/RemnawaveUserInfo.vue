<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import RemnawaveAPI from 'dashboard/api/integrations/remnawave';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const contact = useFunctionGetter('contacts/getContact', props.contactId);

const telegramId = computed(
  () => contact.value?.additional_attributes?.social_telegram_user_id
);

const user = ref(null);
const loading = ref(false);
const error = ref('');
const actionLoading = ref('');

const statusColors = {
  ACTIVE: 'bg-n-teal-5 text-n-teal-12',
  DISABLED: 'bg-n-solid-3 text-n-slate-12',
  LIMITED: 'bg-n-amber-5 text-n-amber-12',
  EXPIRED: 'bg-n-ruby-5 text-n-ruby-12',
};

const formatBytes = bytes => {
  if (bytes === 0 || bytes === null || bytes === undefined) return '0 B';
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
};

const formatDate = dateString => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const statusLabel = computed(() => {
  if (!user.value?.status) return '';
  return t(
    `CONVERSATION_SIDEBAR.REMNAWAVE.USER_STATUS.${user.value.status}`
  );
});

const trafficStrategyLabel = computed(() => {
  if (!user.value?.traffic_limit_strategy) return '';
  return t(
    `CONVERSATION_SIDEBAR.REMNAWAVE.TRAFFIC_STRATEGY.${user.value.traffic_limit_strategy}`
  );
});

const trafficLimitDisplay = computed(() => {
  if (!user.value) return '';
  if (user.value.traffic_limit_bytes === 0) {
    return t('CONVERSATION_SIDEBAR.REMNAWAVE.UNLIMITED');
  }
  return formatBytes(user.value.traffic_limit_bytes);
});

const isUserActive = computed(() => user.value?.status === 'ACTIVE');

const fetchUserInfo = async () => {
  if (!telegramId.value) {
    error.value = 'no_telegram_id';
    return;
  }

  try {
    loading.value = true;
    error.value = '';
    const response = await RemnawaveAPI.getUserInfo(props.contactId);
    user.value = response.data.user;
  } catch (e) {
    const errorCode = e.response?.data?.error;
    if (errorCode === 'not_configured') {
      error.value = 'not_configured';
    } else if (errorCode === 'user_not_found' || e.response?.status === 404) {
      error.value = 'user_not_found';
    } else {
      error.value = 'generic';
    }
  } finally {
    loading.value = false;
  }
};

const performAction = async (action, successKey) => {
  if (!user.value?.uuid || actionLoading.value) return;

  try {
    actionLoading.value = action;
    let response;

    if (action === 'enable') {
      response = await RemnawaveAPI.enableUser(user.value.uuid);
    } else if (action === 'disable') {
      response = await RemnawaveAPI.disableUser(user.value.uuid);
    } else if (action === 'reset_traffic') {
      response = await RemnawaveAPI.resetTraffic(user.value.uuid);
    }

    if (response?.data?.user) {
      user.value = response.data.user;
    }
    useAlert(t(`CONVERSATION_SIDEBAR.REMNAWAVE.ACTIONS.${successKey}`));
  } catch {
    useAlert(t('CONVERSATION_SIDEBAR.REMNAWAVE.ACTIONS.ERROR'));
  } finally {
    actionLoading.value = '';
  }
};

watch(
  () => props.contactId,
  () => fetchUserInfo(),
  { immediate: true }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>

    <div v-else-if="error === 'no_telegram_id'" class="text-center text-sm text-n-slate-11 py-2">
      {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.NO_TELEGRAM_ID') }}
    </div>

    <div v-else-if="error === 'not_configured'" class="text-center text-sm text-n-slate-11 py-2">
      {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.NOT_CONFIGURED') }}
    </div>

    <div v-else-if="error === 'user_not_found'" class="text-center text-sm text-n-slate-11 py-2">
      {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.USER_NOT_FOUND') }}
    </div>

    <div v-else-if="error" class="text-center text-sm text-n-ruby-12 py-2">
      {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.ERROR') }}
    </div>

    <div v-else-if="user" class="flex flex-col gap-2">
      <!-- Status + Username -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium truncate" :title="user.username">
          {{ user.username }}
        </span>
        <span
          :class="statusColors[user.status] || 'bg-n-solid-3 text-n-slate-12'"
          class="text-xs px-2 py-0.5 rounded capitalize"
        >
          {{ statusLabel }}
        </span>
      </div>

      <!-- Traffic -->
      <div class="flex flex-col gap-1 text-sm">
        <div class="flex justify-between">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.TRAFFIC_USED') }}
          </span>
          <span>{{ formatBytes(user.used_traffic_bytes) }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.TRAFFIC_LIMIT') }}
          </span>
          <span>{{ trafficLimitDisplay }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.TRAFFIC_RESET_STRATEGY') }}
          </span>
          <span>{{ trafficStrategyLabel }}</span>
        </div>
      </div>

      <!-- Expiration -->
      <div class="flex justify-between text-sm">
        <span class="text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.EXPIRES_AT') }}
        </span>
        <span>{{ formatDate(user.expire_at) }}</span>
      </div>

      <!-- Subscription URL -->
      <div v-if="user.subscription_url" class="text-sm">
        <div class="text-n-slate-11 mb-0.5">
          {{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.SUBSCRIPTION_URL') }}
        </div>
        <a
          :href="user.subscription_url"
          target="_blank"
          rel="noopener noreferrer"
          class="text-n-brand truncate block hover:underline"
          :title="user.subscription_url"
        >
          {{ user.subscription_url }}
        </a>
      </div>

      <!-- Actions -->
      <div class="flex gap-2 mt-1 border-t border-n-weak pt-2">
        <button
          v-if="!isUserActive"
          class="flex-1 text-xs px-2 py-1.5 rounded bg-n-teal-5 text-n-teal-12 hover:bg-n-teal-6 transition-colors disabled:opacity-50"
          :disabled="!!actionLoading"
          @click="performAction('enable', 'ENABLE_SUCCESS')"
        >
          <span v-if="actionLoading === 'enable'">...</span>
          <span v-else>{{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.ACTIONS.ENABLE') }}</span>
        </button>
        <button
          v-if="isUserActive"
          class="flex-1 text-xs px-2 py-1.5 rounded bg-n-ruby-5 text-n-ruby-12 hover:bg-n-ruby-6 transition-colors disabled:opacity-50"
          :disabled="!!actionLoading"
          @click="performAction('disable', 'DISABLE_SUCCESS')"
        >
          <span v-if="actionLoading === 'disable'">...</span>
          <span v-else>{{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.ACTIONS.DISABLE') }}</span>
        </button>
        <button
          class="flex-1 text-xs px-2 py-1.5 rounded bg-n-solid-3 text-n-slate-12 hover:bg-n-solid-4 transition-colors disabled:opacity-50"
          :disabled="!!actionLoading"
          @click="performAction('reset_traffic', 'RESET_TRAFFIC_SUCCESS')"
        >
          <span v-if="actionLoading === 'reset_traffic'">...</span>
          <span v-else>{{ $t('CONVERSATION_SIDEBAR.REMNAWAVE.ACTIONS.RESET_TRAFFIC') }}</span>
        </button>
      </div>
    </div>
  </div>
</template>
