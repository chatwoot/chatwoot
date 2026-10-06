<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useBranding } from 'shared/composables/useBranding';
import oauthAPI from 'dashboard/api/oauth';
import {
  OAUTH_AUTHORIZE_PARAMS,
  OAUTH_SCOPE_LABELS,
} from 'dashboard/constants/oauth';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const currentUser = useMapGetter('getCurrentUser');

const authorization = ref(null);
const errorDescription = ref('');
const isLoading = ref(true);
const isSubmitting = ref(false);
const selectedAccountId = ref(Number(route.params.accountId));

const oauthParams = computed(() =>
  Object.fromEntries(
    OAUTH_AUTHORIZE_PARAMS.filter(param => route.query[param]).map(param => [
      param,
      route.query[param],
    ])
  )
);

const accountOptions = computed(() =>
  (currentUser.value.accounts || []).map(account => ({
    value: account.id,
    label: account.name,
  }))
);

const scopes = computed(() => authorization.value.scope.split(' '));

const redirectHost = computed(
  () => new URL(authorization.value.redirect_uri).host
);

const fetchAuthorization = async () => {
  try {
    const { data } = await oauthAPI.getAuthorization(oauthParams.value);
    authorization.value = data;
  } catch (error) {
    errorDescription.value = error.response?.data?.error_description || '';
  } finally {
    isLoading.value = false;
  }
};

// The client finishes the flow, so both answers end by sending the browser back to it
const respond = async request => {
  isSubmitting.value = true;
  try {
    const { data } = await request;
    window.location.assign(data.redirect_uri);
  } catch (error) {
    authorization.value = null;
    errorDescription.value = error.response?.data?.error_description || '';
    isSubmitting.value = false;
  }
};

const approve = () =>
  respond(
    oauthAPI.approveAuthorization({
      ...oauthParams.value,
      account_id: selectedAccountId.value,
    })
  );

const deny = () => respond(oauthAPI.denyAuthorization(oauthParams.value));

onMounted(fetchAuthorization);
</script>

<template>
  <div
    class="flex min-h-screen items-center justify-center bg-n-background p-6"
  >
    <div
      class="flex w-full max-w-lg flex-col gap-6 rounded-xl border border-n-weak bg-n-solid-1 p-6 shadow"
    >
      <div v-if="isLoading" class="flex justify-center text-n-slate-11">
        <Spinner />
      </div>
      <template v-else-if="authorization">
        <div class="flex flex-col gap-2">
          <h1 class="text-heading-2 text-n-slate-12">
            {{
              replaceInstallationName(
                t('OAUTH.AUTHORIZE.TITLE', {
                  appName: authorization.client_name,
                })
              )
            }}
          </h1>
          <p class="text-body-main text-n-slate-11">
            {{
              t('OAUTH.AUTHORIZE.DESCRIPTION', {
                appName: authorization.client_name,
              })
            }}
          </p>
        </div>
        <ul class="flex flex-col gap-3">
          <li
            v-for="scope in scopes"
            :key="scope"
            class="flex items-start gap-2 text-body-main text-n-slate-12"
          >
            <Icon
              icon="i-lucide-check"
              class="mt-0.5 size-4 flex-shrink-0 text-n-teal-11"
            />
            {{ t(OAUTH_SCOPE_LABELS[scope]) }}
          </li>
        </ul>
        <div class="flex flex-col gap-2">
          <span class="text-heading-3 text-n-slate-12">
            {{ t('OAUTH.AUTHORIZE.ACCOUNT_LABEL') }}
          </span>
          <ComboBox v-model="selectedAccountId" :options="accountOptions" />
          <span class="text-body-b3 text-n-slate-11">
            {{ t('OAUTH.AUTHORIZE.ACCOUNT_NOTE') }}
          </span>
        </div>
        <div class="flex flex-col gap-3">
          <div class="flex justify-end gap-2">
            <Button
              faded
              slate
              :label="t('OAUTH.AUTHORIZE.DENY')"
              :disabled="isSubmitting"
              @click="deny"
            />
            <Button
              :label="t('OAUTH.AUTHORIZE.ALLOW')"
              :disabled="isSubmitting || !selectedAccountId"
              :is-loading="isSubmitting"
              @click="approve"
            />
          </div>
          <span class="text-body-b3 text-n-slate-10 text-end">
            {{ t('OAUTH.AUTHORIZE.REDIRECT_NOTE', { host: redirectHost }) }}
          </span>
        </div>
      </template>
      <div v-else class="flex flex-col gap-2">
        <h1 class="text-heading-2 text-n-slate-12">
          {{ t('OAUTH.AUTHORIZE.ERROR_TITLE') }}
        </h1>
        <p class="text-body-main text-n-slate-11">
          {{ t('OAUTH.AUTHORIZE.ERROR_DESCRIPTION') }}
        </p>
        <p v-if="errorDescription" class="text-body-b3 text-n-ruby-11">
          {{ errorDescription }}
        </p>
      </div>
    </div>
  </div>
</template>
