<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';
import { useBranding } from 'shared/composables/useBranding';
import StripeAPI from 'dashboard/api/integrations/stripe';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const { replaceInstallationName } = useBranding();
const route = useRoute();
const integration = useFunctionGetter('integrations/getIntegration', 'stripe');
const loading = ref(true);
const busy = ref(false);
const error = ref(!!route.query.error);
const account = ref(null);
const STRIPE_LOGO = '/dashboard/images/integrations/stripe.svg';
const STRIPE_LOGO_DARK = '/dashboard/images/integrations/stripe-dark.svg';

const loadIntegration = async () => {
  await store.dispatch('integrations/get', 'stripe');
  account.value = integration.value.enabled
    ? (await StripeAPI.get()).data
    : null;
};

const connect = async () => {
  busy.value = true;
  error.value = false;
  try {
    const { data } = await StripeAPI.connect();
    window.location.assign(data.url);
  } catch {
    error.value = true;
  } finally {
    busy.value = false;
  }
};

const disconnect = async () => {
  busy.value = true;
  error.value = false;
  try {
    await StripeAPI.disconnect();
    await loadIntegration();
  } catch {
    error.value = true;
  } finally {
    busy.value = false;
  }
};

onMounted(async () => {
  try {
    await loadIntegration();
  } catch {
    error.value = true;
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <SettingsLayout :is-loading="loading">
    <template #header>
      <BaseSettingsHeader
        :title="$t('STRIPE_INTEGRATION.TITLE')"
        :description="$t('STRIPE_INTEGRATION.DESCRIPTION')"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6 w-full text-n-slate-12">
        <p v-if="error" role="alert" class="text-n-ruby-11">
          {{ $t('STRIPE_INTEGRATION.ERROR') }}
        </p>
        <template v-if="integration.enabled">
          <div class="rounded-xl border border-n-weak bg-n-solid-1">
            <div
              class="flex flex-wrap items-center justify-between gap-4 p-6 border-b border-n-weak"
            >
              <div class="flex items-center gap-3">
                <img :src="STRIPE_LOGO" alt="Stripe" class="w-16 dark:hidden" />
                <img
                  :src="STRIPE_LOGO_DARK"
                  alt="Stripe"
                  class="w-16 hidden dark:block"
                />
                <span class="text-sm font-medium">{{
                  $t('STRIPE_INTEGRATION.ACCOUNT')
                }}</span>
              </div>
              <span
                class="rounded-md bg-n-teal-3 px-2 py-1 text-xs text-n-teal-11"
              >
                {{ $t('STRIPE_INTEGRATION.CONNECTED') }}
              </span>
            </div>
            <dl
              v-if="account"
              class="grid grid-cols-1 sm:grid-cols-[10rem_1fr] gap-x-8 gap-y-3 p-6 text-sm m-0"
            >
              <dt class="text-n-slate-11">
                {{ $t('STRIPE_INTEGRATION.ACCOUNT_ID') }}
              </dt>
              <dd class="m-0 break-all font-mono text-xs self-center">
                {{ account.account_id }}
              </dd>
              <dt class="text-n-slate-11">
                {{ $t('STRIPE_INTEGRATION.ENVIRONMENT') }}
              </dt>
              <dd class="m-0">
                {{
                  account.mode === 'live'
                    ? $t('STRIPE_INTEGRATION.LIVE')
                    : $t('STRIPE_INTEGRATION.SANDBOX')
                }}
              </dd>
              <dt class="text-n-slate-11">
                {{ $t('STRIPE_INTEGRATION.CONNECTED_ON') }}
              </dt>
              <dd class="m-0">
                {{ new Date(account.connected_at).toLocaleDateString() }}
              </dd>
            </dl>
            <div class="px-6 pb-6">
              <a
                v-if="account"
                :href="`https://dashboard.stripe.com/${account.account_id}/${account.mode === 'live' ? '' : 'test/'}dashboard`"
                target="_blank"
                rel="noopener noreferrer"
                class="text-sm text-n-brand hover:underline"
              >
                {{ $t('STRIPE_INTEGRATION.OPEN_STRIPE') }}
              </a>
            </div>
          </div>
          <div
            class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-xl border border-n-weak p-6"
          >
            <p class="m-0 text-sm text-n-slate-11 max-w-xl">
              {{
                replaceInstallationName(
                  $t('STRIPE_INTEGRATION.DISCONNECT_NOTE')
                )
              }}
            </p>
            <Button
              :label="
                replaceInstallationName($t('STRIPE_INTEGRATION.DISCONNECT'))
              "
              :disabled="busy"
              variant="outline"
              color="ruby"
              @click="disconnect"
            />
          </div>
        </template>
        <Button
          v-else
          :label="$t('STRIPE_INTEGRATION.CONNECT')"
          :disabled="busy"
          class="self-start"
          @click="connect"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
