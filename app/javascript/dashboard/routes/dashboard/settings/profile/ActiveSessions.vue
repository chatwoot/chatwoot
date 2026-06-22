<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow, parseISO } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import authAPI from 'dashboard/api/auth';
import AnalyticsHelper from 'dashboard/helper/AnalyticsHelper';
import { SESSION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const sessions = ref([]);
const loading = ref(false);

const relativeTime = dateStr => {
  if (!dateStr) return '';
  return formatDistanceToNow(parseISO(dateStr), { addSuffix: true });
};

const isUnknown = val => !val || val === 'Unknown' || val === 'Unknown Browser';

const deviceIcon = session => {
  const name = (session.device_name || '').toLowerCase();
  if (
    name.includes('iphone') ||
    name.includes('android') ||
    name.includes('mobile')
  ) {
    return 'i-lucide-smartphone';
  }
  if (name.includes('ipad') || name.includes('tablet')) {
    return 'i-lucide-tablet';
  }
  return 'i-lucide-monitor';
};

const sessionLabel = session => {
  const parts = [];
  if (!isUnknown(session.browser_name)) {
    parts.push(
      session.browser_version
        ? `${session.browser_name} ${session.browser_version}`
        : session.browser_name
    );
  }
  if (!isUnknown(session.platform_name)) parts.push(session.platform_name);
  return (
    parts.join(' on ') ||
    t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.UNKNOWN_DEVICE')
  );
};

const locationLabel = session => {
  const parts = [];
  if (session.city) parts.push(session.city);
  if (session.country) parts.push(session.country);
  return parts.join(', ');
};

const fetchSessions = async () => {
  loading.value = true;
  try {
    const { data } = await authAPI.getSessions();
    sessions.value = data;
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.FETCH_ERROR'));
  } finally {
    loading.value = false;
  }
};

const revokeSession = async session => {
  try {
    await authAPI.revokeSession(session.id);
    sessions.value = sessions.value.filter(s => s.id !== session.id);
    AnalyticsHelper.track(SESSION_EVENTS.REVOKED_FROM_PROFILE);
    useAlert(t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.REVOKE_SUCCESS'));
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.REVOKE_ERROR'));
  }
};

onMounted(fetchSessions);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div
      v-for="session in sessions"
      :key="session.id"
      class="flex items-center justify-between gap-4 rounded-xl border border-n-slate-4 bg-n-background p-4"
    >
      <div class="flex items-start gap-3">
        <Icon
          :icon="deviceIcon(session)"
          class="size-5 mt-0.5 text-n-slate-10 flex-shrink-0"
        />
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-heading-3 text-n-slate-12">
              {{ sessionLabel(session) }}
            </span>
            <span
              v-if="session.current"
              class="rounded-full bg-n-teal-3 px-2 py-0.5 text-caption text-n-teal-11"
            >
              {{ $t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.CURRENT') }}
            </span>
          </div>
          <span
            v-if="locationLabel(session)"
            class="text-body-b3 text-n-slate-11"
          >
            {{ locationLabel(session) }}
          </span>
          <span
            v-if="session.last_activity_at"
            class="text-body-b3 text-n-slate-10"
          >
            {{ $t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.LAST_ACTIVE') }}
            {{ relativeTime(session.last_activity_at) }}
          </span>
        </div>
      </div>
      <Button
        v-if="!session.current"
        type="button"
        faded
        xs
        :label="$t('PROFILE_SETTINGS.FORM.SESSIONS_SECTION.REVOKE')"
        color="ruby"
        @click="revokeSession(session)"
      />
    </div>
  </div>
</template>
