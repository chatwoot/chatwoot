<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import IntegrationsAPI from 'dashboard/api/integrations';

const { t } = useI18n();
const store = useStore();
const { replaceInstallationName } = useBranding();

const accessToken = ref('');
const hook = ref(null);
const isLoading = ref(true);
const isSaving = ref(false);
const isDeleting = ref(false);

const connected = computed(() => !!hook.value?.id);

const dataImportsURL = computed(() =>
  frontendURL(`accounts/${store.getters.getCurrentAccountId}/settings/data`)
);

const fetchConnection = async () => {
  const response = await IntegrationsAPI.getIntercom();
  hook.value = response.data;
};

const connect = async () => {
  isSaving.value = true;
  try {
    const response = await IntegrationsAPI.connectIntercom({
      accessToken: accessToken.value,
    });
    hook.value = response.data;
    accessToken.value = '';
    await store.dispatch('integrations/get');
    useAlert(t('INTEGRATION_SETTINGS.INTERCOM.CONNECTED'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('INTEGRATION_SETTINGS.INTERCOM.CONNECT_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

const disconnect = async () => {
  isDeleting.value = true;
  try {
    await IntegrationsAPI.disconnectIntercom();
    hook.value = null;
    await store.dispatch('integrations/get');
    useAlert(t('INTEGRATION_SETTINGS.INTERCOM.DISCONNECTED'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('INTEGRATION_SETTINGS.INTERCOM.DISCONNECT_ERROR')
    );
  } finally {
    isDeleting.value = false;
  }
};

onMounted(async () => {
  try {
    await fetchConnection();
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('INTEGRATION_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.INTERCOM.HEADER')"
        :description="
          replaceInstallationName(
            $t('INTEGRATION_SETTINGS.INTERCOM.DESCRIPTION')
          )
        "
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div
        class="rounded-lg bg-n-card outline outline-1 outline-n-container p-6 flex flex-col gap-5"
      >
        <div v-if="connected" class="flex flex-col gap-4">
          <div>
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('INTEGRATION_SETTINGS.INTERCOM.CONNECTED_TITLE') }}
            </h2>
            <p class="text-body-main text-n-slate-11 mt-1">
              {{
                $t('INTEGRATION_SETTINGS.INTERCOM.LAST_VALIDATED', {
                  date: hook.settings?.last_validated_at || '-',
                })
              }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <router-link :to="dataImportsURL">
              <Button
                :label="$t('INTEGRATION_SETTINGS.INTERCOM.GO_TO_IMPORTS')"
                icon="i-lucide-download"
              />
            </router-link>
            <Button
              faded
              ruby
              :label="$t('INTEGRATION_SETTINGS.INTERCOM.DISCONNECT')"
              :is-loading="isDeleting"
              @click="disconnect"
            />
          </div>
        </div>

        <form
          v-else
          class="flex flex-col gap-4 max-w-xl"
          @submit.prevent="connect"
        >
          <Input
            v-model="accessToken"
            type="password"
            :label="$t('INTEGRATION_SETTINGS.INTERCOM.ACCESS_TOKEN.LABEL')"
            :placeholder="
              $t('INTEGRATION_SETTINGS.INTERCOM.ACCESS_TOKEN.PLACEHOLDER')
            "
          />
          <p class="text-body-main text-n-slate-11">
            {{ $t('INTEGRATION_SETTINGS.INTERCOM.ACCESS_TOKEN.HELP') }}
          </p>
          <div>
            <Button
              type="submit"
              :label="$t('INTEGRATION_SETTINGS.INTERCOM.CONNECT')"
              icon="i-lucide-plug"
              :is-loading="isSaving"
              :disabled="!accessToken || isSaving"
            />
          </div>
        </form>
      </div>
    </template>
  </SettingsLayout>
</template>
