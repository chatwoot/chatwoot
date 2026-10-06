<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow, getUnixTime, parseISO } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import oauthAPI from 'dashboard/api/oauth';
import { OAUTH_SCOPE_LABELS } from 'dashboard/constants/oauth';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const exactTimestamp = useExactTimestamp();
const apps = ref([]);
const isLoading = ref(true);

const relativeTime = dateStr =>
  formatDistanceToNow(parseISO(dateStr), { addSuffix: true });

const exactTime = dateStr => exactTimestamp(getUnixTime(parseISO(dateStr)));

const fetchApps = async () => {
  try {
    const { data } = await oauthAPI.getConnectedApps();
    apps.value = data;
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const revokeApp = async app => {
  try {
    await oauthAPI.revokeConnectedApp(app.id);
    apps.value = apps.value.filter(a => a.id !== app.id);
    useAlert(t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.REVOKE_SUCCESS'));
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.REVOKE_ERROR'));
  }
};

onMounted(fetchApps);
</script>

<template>
  <div class="flex flex-col gap-3">
    <p v-if="!isLoading && !apps.length" class="text-body-main text-n-slate-11">
      {{ $t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.EMPTY') }}
    </p>
    <div
      v-for="app in apps"
      :key="app.id"
      class="flex items-center justify-between gap-4 rounded-xl border border-n-slate-4 bg-n-background p-4"
    >
      <div class="flex items-start gap-3">
        <Icon
          icon="i-lucide-plug"
          class="size-5 mt-0.5 text-n-slate-10 flex-shrink-0"
        />
        <div class="flex flex-col gap-1">
          <span class="text-heading-3 text-n-slate-12">{{ app.name }}</span>
          <span class="text-body-b3 text-n-slate-11">
            {{ app.accounts.join(', ') }}
          </span>
          <ul class="flex flex-col text-body-b3 text-n-slate-11">
            <li v-for="scope in app.scopes" :key="scope">
              {{ $t(OAUTH_SCOPE_LABELS[scope]) }}
            </li>
          </ul>
          <span
            v-if="app.authorized_at"
            v-tooltip.top="{
              content: exactTime(app.authorized_at),
              delay: { show: 500, hide: 0 },
            }"
            class="text-body-b3 text-n-slate-10"
          >
            {{ $t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.CONNECTED') }}
            {{ relativeTime(app.authorized_at) }}
          </span>
        </div>
      </div>
      <Button
        type="button"
        faded
        xs
        :label="$t('PROFILE_SETTINGS.FORM.CONNECTED_APPS_SECTION.REVOKE')"
        color="ruby"
        @click="revokeApp(app)"
      />
    </div>
  </div>
</template>
