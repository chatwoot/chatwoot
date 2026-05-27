<script setup>
import { computed, onUnmounted, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { parseBoolean } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import mfaAPI from 'dashboard/api/mfa';
import Banner from 'dashboard/components/ui/Banner.vue';

const LOW_BACKUP_CODES_THRESHOLD = 3;

const { t } = useI18n();
const router = useRouter();

const mfaEnabled = ref(false);
const remainingBackupCodes = ref(null);

const currentAccountId = useMapGetter('getCurrentAccountId');

const shouldShowBanner = computed(() => {
  if (!mfaEnabled.value) return false;
  if (remainingBackupCodes.value === null) return false;
  return remainingBackupCodes.value <= LOW_BACKUP_CODES_THRESHOLD;
});

const bannerColorScheme = computed(() =>
  remainingBackupCodes.value === 0 ? 'alert' : 'warning'
);

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
  <Banner
    v-if="shouldShowBanner"
    :color-scheme="bannerColorScheme"
    :banner-message="bannerMessage"
    :action-button-label="$t('MFA_SETTINGS.LOW_BACKUP_CODES.ACTION')"
    action-button-icon="i-lucide-key"
    has-action-button
    @primary-action="goToMfaSettings"
  />
</template>
