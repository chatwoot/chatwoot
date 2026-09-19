<script setup>
import { computed, onUnmounted, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { parseBoolean } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import mfaAPI from 'dashboard/api/mfa';

const LOW_BACKUP_CODES_THRESHOLD = 3;

// Matches the amber/ruby subtle treatment used for warning callouts elsewhere
// in the design system (e.g. CoverageBanner, InboxBanner, NextBanner).
const SEVERITY_CLASSES = {
  warning: {
    container: 'bg-n-amber-3 border-n-amber-4 text-n-amber-11',
    action: 'bg-n-amber-4 hover:bg-n-amber-5',
    dismiss: 'hover:bg-n-amber-4',
  },
  critical: {
    container: 'bg-n-ruby-3 border-n-ruby-4 text-n-ruby-11',
    action: 'bg-n-ruby-4 hover:bg-n-ruby-5',
    dismiss: 'hover:bg-n-ruby-4',
  },
};

const { t } = useI18n();
const router = useRouter();

const mfaEnabled = ref(false);
const remainingBackupCodes = ref(null);
const dismissed = ref(false);

const currentAccountId = useMapGetter('getCurrentAccountId');

const shouldShowBanner = computed(() => {
  if (dismissed.value) return false;
  if (!mfaEnabled.value) return false;
  if (remainingBackupCodes.value === null) return false;
  return remainingBackupCodes.value <= LOW_BACKUP_CODES_THRESHOLD;
});

const severity = computed(() =>
  remainingBackupCodes.value === 0 ? 'critical' : 'warning'
);

const severityClasses = computed(() => SEVERITY_CLASSES[severity.value]);

const bannerMessage = computed(() => {
  if (remainingBackupCodes.value === 0) {
    return t('MFA_SETTINGS.LOW_BACKUP_CODES.NONE_LEFT');
  }
  return t('MFA_SETTINGS.LOW_BACKUP_CODES.MESSAGE', remainingBackupCodes.value);
});

const fetchMfaStatus = async () => {
  if (!parseBoolean(window.chatwootConfig?.isMfaEnabled)) return;

  try {
    const { data } = await mfaAPI.get();
    mfaEnabled.value = data.enabled;
    remainingBackupCodes.value = data.remaining_backup_codes ?? null;
  } catch {
    // ignore; banner stays hidden
  }
};

const goToMfaSettings = () => {
  router.push({
    name: 'profile_settings_mfa',
    params: { accountId: currentAccountId.value },
  });
};

const dismissBanner = () => {
  dismissed.value = true;
};

onMounted(() => {
  fetchMfaStatus();
  emitter.on(BUS_EVENTS.MFA_STATE_CHANGED, fetchMfaStatus);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.MFA_STATE_CHANGED, fetchMfaStatus);
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="shouldShowBanner"
    class="flex items-center justify-between gap-3 px-4 py-2 text-sm border-b"
    :class="severityClasses.container"
  >
    <div class="flex items-center min-w-0 gap-2">
      <span class="shrink-0 i-lucide-triangle-alert size-4" />
      <span class="truncate">{{ bannerMessage }}</span>
    </div>
    <div class="flex items-center gap-1 shrink-0">
      <button
        type="button"
        class="px-3 py-1 rounded-lg whitespace-nowrap"
        :class="severityClasses.action"
        @click="goToMfaSettings"
      >
        {{ $t('MFA_SETTINGS.LOW_BACKUP_CODES.ACTION') }}
      </button>
      <button
        type="button"
        class="grid rounded-lg size-7 place-content-center"
        :class="severityClasses.dismiss"
        :aria-label="$t('GENERAL_SETTINGS.DISMISS')"
        @click="dismissBanner"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>
  </div>
</template>
