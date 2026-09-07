<script setup>
import { computed, nextTick, reactive, ref } from 'vue';
import { I18nT, useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useTimeoutPoll } from '@vueuse/core';

import WhatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import ManualSetupVideo from './whatsapp/ManualSetupVideo.vue';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const route = useRoute();
const router = useRouter();
const store = useStore();

const TOTAL_STEPS = 5;
const POLL_INTERVAL = 2000;
const MAX_POLL_ATTEMPTS = 5;
const META_APPS_URL = 'https://developers.facebook.com/apps/';
const META_BUSINESS_SETTINGS_URL =
  'https://business.facebook.com/settings/system-users/';
const VIDEO_BASE_URL = '/videos/whatsapp/manual-setup';
const VIDEOS = {
  app: {
    src: `${VIDEO_BASE_URL}/create-meta-app.mp4`,
    poster: `${VIDEO_BASE_URL}/create-meta-app-poster.jpg`,
  },
  number: {
    src: `${VIDEO_BASE_URL}/add-phone-number.mp4`,
    poster: `${VIDEO_BASE_URL}/add-phone-number-poster.jpg`,
  },
  token: {
    src: `${VIDEO_BASE_URL}/generate-access-token.mp4`,
    poster: `${VIDEO_BASE_URL}/generate-access-token-poster.jpg`,
  },
};

const currentStep = ref(1);
const isLoading = ref(false);
const errorMessage = ref('');
const inboxId = ref(null);
const showAccessToken = ref(false);
const setupRoot = ref(null);
const pollAttempts = ref(0);

const form = reactive({
  wabaId: '',
  phoneNumberId: '',
  accessToken: '',
  inboxName: '',
});

const preview = ref(null);
const connection = reactive({
  numberAccess: false,
  templateAccess: false,
  callbackConfigured: false,
  callbackUrl: '',
  subscriptionVerified: false,
});

const idsComplete = computed(
  () => form.wabaId.trim() && form.phoneNumberId.trim()
);

const detailsComplete = computed(
  () => idsComplete.value && form.accessToken.trim()
);

const connectionReady = computed(
  () =>
    connection.numberAccess &&
    connection.templateAccess &&
    connection.callbackConfigured &&
    connection.subscriptionVerified
);

const appInstructions = computed(() => [
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.ITEM_2'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.ITEM_3'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.ITEM_4'),
]);

const numberInstructions = computed(() => [
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_1'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_2'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_3'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_4'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_5'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.ITEM_6'),
]);

const tokenInstructions = computed(() => [
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_1'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_2'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_3'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_4'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_5'),
  t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.ITEM_6'),
]);

const statusRows = computed(() => [
  {
    key: 'number',
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.NUMBER_ACCESS'),
    complete: connection.numberAccess,
  },
  {
    key: 'templates',
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.TEMPLATE_ACCESS'),
    complete: connection.templateAccess,
  },
  {
    key: 'callback',
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.CALLBACK'),
    complete: connection.callbackConfigured,
  },
  {
    key: 'subscription',
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.SUBSCRIPTION'),
    complete: connection.subscriptionVerified,
  },
]);

const reviewRows = computed(() => [
  {
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.BUSINESS_NAME'),
    value: preview.value.verified_name || preview.value.display_phone_number,
  },
  {
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.PHONE_NUMBER'),
    value: preview.value.display_phone_number,
  },
  {
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.PHONE_ID'),
    value: preview.value.phone_number_id,
  },
  {
    label: t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.WABA_ID'),
    value: preview.value.waba_id,
  },
]);

const apiErrorMessage = error => {
  const message = error.response?.data?.message || '';
  if (/invalid oauth access token|cannot parse access token/i.test(message)) {
    return t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ERRORS.INVALID_TOKEN');
  }

  return message || t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ERRORS.GENERIC');
};

const setStep = step => {
  errorMessage.value = '';
  currentStep.value = step;
  nextTick(() => setupRoot.value?.scrollIntoView({ block: 'start' }));
};

const returnToProviders = () => {
  router.push({
    name: route.name,
    params: route.params,
    query: {},
  });
};

const goBack = () => {
  if (currentStep.value > 1) {
    setStep(currentStep.value - 1);
    return;
  }

  returnToProviders();
};

const continueFromIds = () => {
  if (!idsComplete.value) {
    errorMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ERRORS.IDS_REQUIRED'
    );
    return;
  }

  setStep(3);
};

const verifyDetails = async () => {
  if (!detailsComplete.value) {
    errorMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ERRORS.REQUIRED'
    );
    return;
  }

  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await WhatsappChannelAPI.previewManualSetup({
      waba_id: form.wabaId.trim(),
      phone_number_id: form.phoneNumberId.trim(),
      access_token: form.accessToken.trim(),
    });
    preview.value = data;
    form.inboxName = data.suggested_inbox_name;
    setStep(4);
  } catch (error) {
    errorMessage.value = apiErrorMessage(error);
  } finally {
    isLoading.value = false;
  }
};

const applyWebhookStatus = status => {
  connection.callbackConfigured = Boolean(status.callback_configured);
  connection.callbackUrl = status.callback_url || '';
  connection.subscriptionVerified = Boolean(status.subscription_verified);
};

const copyWebhookUrl = async () => {
  await copyTextToClipboard(connection.callbackUrl);
  useAlert(t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.COPY_SUCCESS'));
};

const refreshWebhookStatus = async ({ showError = true } = {}) => {
  if (!inboxId.value) return;

  try {
    const { data } = await WhatsappChannelAPI.getManualWebhookStatus(
      inboxId.value
    );
    applyWebhookStatus(data);
  } catch (error) {
    if (showError) errorMessage.value = apiErrorMessage(error);
  }
};

const { resume: resumePolling, pause: pausePolling } = useTimeoutPoll(
  async () => {
    await refreshWebhookStatus({ showError: false });
    pollAttempts.value += 1;
    if (connectionReady.value || pollAttempts.value >= MAX_POLL_ATTEMPTS) {
      pausePolling();
    }
  },
  POLL_INTERVAL,
  { immediate: false }
);

const startPolling = () => {
  pollAttempts.value = 0;
  resumePolling();
};

const connectNumber = async () => {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await WhatsappChannelAPI.connectManualSetup({
      waba_id: form.wabaId.trim(),
      phone_number_id: form.phoneNumberId.trim(),
      access_token: form.accessToken.trim(),
      inbox_name: form.inboxName.trim(),
    });
    inboxId.value = data.id;
    connection.numberAccess = Boolean(data.number_access);
    connection.templateAccess = Boolean(data.template_access);
    if (data.webhook_error) errorMessage.value = data.webhook_error;
    currentStep.value = 5;
    startPolling();
  } catch (error) {
    errorMessage.value = apiErrorMessage(error);
  } finally {
    isLoading.value = false;
  }
};

const retryWebhookSetup = async () => {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await WhatsappChannelAPI.setupManualWebhook(inboxId.value);
    applyWebhookStatus(data);
    if (!connectionReady.value) startPolling();
  } catch (error) {
    errorMessage.value = apiErrorMessage(error);
  } finally {
    isLoading.value = false;
  }
};

const continueToAgents = async () => {
  await store.dispatch('inboxes/get');
  router.replace({
    name: 'settings_inboxes_add_agents',
    params: { page: 'new', inbox_id: inboxId.value },
  });
};
</script>

<template>
  <div
    ref="setupRoot"
    class="mx-auto flex w-full max-w-6xl flex-col gap-4 py-2"
  >
    <div class="px-1">
      <div class="min-w-0 flex-1">
        <h1 class="text-heading-1 text-n-slate-12">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.HEADER.TITLE') }}
        </h1>
        <p class="mt-1 text-body-main text-n-slate-11">
          {{
            replaceInstallationName(
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.HEADER.DESCRIPTION')
            )
          }}
        </p>
      </div>
    </div>

    <div class="rounded-2xl border border-n-weak bg-n-surface-2 p-5">
      <div class="flex justify-end">
        <div class="grid w-40 grid-cols-5 gap-1.5">
          <div
            v-for="step in TOTAL_STEPS"
            :key="step"
            class="h-1.5 rounded-full"
            :class="step <= currentStep ? 'bg-n-brand' : 'bg-n-slate-3'"
          />
        </div>
      </div>

      <Banner
        v-if="errorMessage && currentStep !== 3"
        color="ruby"
        class="mt-6"
      >
        {{ errorMessage }}
      </Banner>

      <section v-if="currentStep === 1" class="mt-3 grid gap-5 lg:grid-cols-2">
        <div class="lg:col-span-2">
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.TITLE') }}
          </h2>
          <p class="mt-2 max-w-3xl text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.DESCRIPTION') }}
          </p>
        </div>

        <ol
          class="ms-5 list-decimal space-y-3 text-body-main text-n-slate-11 marker:font-medium marker:text-n-slate-12"
        >
          <li class="ps-2">
            <I18nT
              keypath="INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.ITEM_1"
              tag="span"
            >
              <template #metaDevelopers>
                <a
                  :href="META_APPS_URL"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="font-medium text-n-brand hover:underline"
                >
                  {{
                    t(
                      'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.META_DEVELOPERS'
                    )
                  }}
                </a>
              </template>
            </I18nT>
          </li>
          <li
            v-for="instruction in appInstructions"
            :key="instruction"
            class="ps-2"
          >
            {{ instruction }}
          </li>
        </ol>

        <ManualSetupVideo
          v-bind="VIDEOS.app"
          class="self-start"
          :title="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.VIDEO_TITLE')"
          :description="
            t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP.VIDEO_DESCRIPTION')
          "
        />

        <div
          class="flex items-center justify-between border-t border-n-weak pt-5 lg:col-span-2"
        >
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.BACK')"
            variant="outline"
            color="slate"
            @click="goBack"
          />
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.APP_READY')"
            trailing-icon
            icon="i-lucide-arrow-right"
            @click="setStep(2)"
          />
        </div>
      </section>

      <section
        v-else-if="currentStep === 2"
        class="mt-3 grid gap-5 lg:grid-cols-2"
      >
        <div class="lg:col-span-2">
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.TITLE') }}
          </h2>
          <p class="mt-2 max-w-3xl text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.DESCRIPTION') }}
          </p>
        </div>

        <ol
          class="ms-5 list-decimal space-y-3 text-body-main text-n-slate-11 marker:font-medium marker:text-n-slate-12"
        >
          <li
            v-for="instruction in numberInstructions"
            :key="instruction"
            class="ps-2"
          >
            {{ instruction }}
          </li>
        </ol>

        <div class="flex min-w-0 flex-col gap-4">
          <ManualSetupVideo
            v-bind="VIDEOS.number"
            :title="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.VIDEO_TITLE')
            "
            :description="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.NUMBER.VIDEO_DESCRIPTION')
            "
          />

          <a
            :href="META_APPS_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex w-fit items-center gap-2 text-sm font-medium text-n-brand hover:underline"
          >
            {{
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.OPEN_META_APPS')
            }}
            <Icon icon="i-lucide-external-link" />
          </a>
        </div>

        <div
          class="grid gap-5 rounded-xl border border-n-weak p-5 lg:col-span-2 lg:grid-cols-2"
        >
          <Input
            v-model="form.phoneNumberId"
            :label="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.PHONE_ID_LABEL')
            "
            :placeholder="
              t(
                'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.PHONE_ID_PLACEHOLDER'
              )
            "
            :message-type="
              errorMessage && !form.phoneNumberId.trim() ? 'error' : 'info'
            "
            @update:model-value="errorMessage = ''"
          />
          <Input
            v-model="form.wabaId"
            :label="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.WABA_LABEL')
            "
            :placeholder="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.WABA_PLACEHOLDER')
            "
            :message-type="
              errorMessage && !form.wabaId.trim() ? 'error' : 'info'
            "
            @update:model-value="errorMessage = ''"
          />
        </div>

        <div
          class="flex items-center justify-between border-t border-n-weak pt-5 lg:col-span-2"
        >
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.BACK')"
            variant="outline"
            color="slate"
            @click="goBack"
          />
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.NEXT')"
            trailing-icon
            icon="i-lucide-arrow-right"
            @click="continueFromIds"
          />
        </div>
      </section>

      <section
        v-else-if="currentStep === 3"
        class="mt-3 grid gap-5 lg:grid-cols-2"
      >
        <div class="lg:col-span-2">
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.TITLE') }}
          </h2>
          <p class="mt-2 max-w-3xl text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.DESCRIPTION') }}
          </p>
        </div>

        <ol
          class="ms-5 list-decimal space-y-3 text-body-main text-n-slate-11 marker:font-medium marker:text-n-slate-12"
        >
          <li
            v-for="instruction in tokenInstructions"
            :key="instruction"
            class="ps-2"
          >
            {{ instruction }}
          </li>
        </ol>

        <div class="flex min-w-0 flex-col gap-4">
          <ManualSetupVideo
            v-bind="VIDEOS.token"
            :title="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.VIDEO_TITLE')"
            :description="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.VIDEO_DESCRIPTION')
            "
          />

          <a
            :href="META_BUSINESS_SETTINGS_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex w-fit items-center gap-2 text-sm font-medium text-n-brand hover:underline"
          >
            {{
              t(
                'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.OPEN_BUSINESS_SETTINGS'
              )
            }}
            <Icon icon="i-lucide-external-link" />
          </a>
        </div>

        <div class="rounded-xl border border-n-weak p-5 lg:col-span-2">
          <div class="grid items-start gap-3 sm:grid-cols-[1fr_auto]">
            <Input
              v-model="form.accessToken"
              :type="showAccessToken ? 'text' : 'password'"
              autocomplete="off"
              :label="
                t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.TOKEN_LABEL')
              "
              :placeholder="
                t(
                  'INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.DETAILS.TOKEN_PLACEHOLDER'
                )
              "
              :message="errorMessage"
              :message-type="errorMessage ? 'error' : 'info'"
              @update:model-value="errorMessage = ''"
            />
            <Button
              :label="
                showAccessToken
                  ? t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.HIDE_TOKEN')
                  : t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.SHOW_TOKEN')
              "
              variant="outline"
              color="slate"
              class="sm:mt-7"
              @click="showAccessToken = !showAccessToken"
            />
          </div>
          <p
            v-if="!errorMessage"
            class="mt-3 flex items-start gap-2 text-sm text-n-amber-11"
          >
            <Icon icon="i-lucide-triangle-alert" class="mt-0.5 shrink-0" />
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.TOKEN.WARNING') }}
          </p>
        </div>

        <div
          class="flex items-center justify-between border-t border-n-weak pt-5 lg:col-span-2"
        >
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.BACK')"
            variant="outline"
            color="slate"
            @click="goBack"
          />
          <Button
            :label="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.VERIFY_DETAILS')
            "
            :is-loading="isLoading"
            :disabled="isLoading"
            @click="verifyDetails"
          />
        </div>
      </section>

      <section v-else-if="currentStep === 4" class="mt-3 flex flex-col gap-5">
        <div>
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.TITLE') }}
          </h2>
          <p class="mt-2 max-w-3xl text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.DESCRIPTION') }}
          </p>
        </div>

        <Banner color="teal">
          <div class="flex items-center gap-2 font-medium">
            <Icon icon="i-lucide-badge-check" />
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.VERIFIED') }}
          </div>
        </Banner>

        <dl class="divide-y divide-n-weak rounded-xl border border-n-weak px-5">
          <div
            v-for="row in reviewRows"
            :key="row.label"
            class="grid grid-cols-2 gap-4 py-4"
          >
            <dt class="text-sm text-n-slate-11">{{ row.label }}</dt>
            <dd class="text-sm font-medium text-n-slate-12">{{ row.value }}</dd>
          </div>
        </dl>

        <Input
          v-model="form.inboxName"
          :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.INBOX_NAME')"
          :message="
            t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.REVIEW.INBOX_NAME_HELP')
          "
        />

        <div
          class="flex items-center justify-between border-t border-n-weak pt-5"
        >
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.BACK')"
            variant="outline"
            color="slate"
            @click="goBack"
          />
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.CONNECT')"
            :is-loading="isLoading"
            :disabled="isLoading || !form.inboxName.trim()"
            @click="connectNumber"
          />
        </div>
      </section>

      <section v-else class="mt-3 flex flex-col gap-5">
        <div>
          <h2 class="text-heading-2 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.TITLE') }}
          </h2>
          <p class="mt-2 max-w-3xl text-body-main text-n-slate-11">
            {{
              replaceInstallationName(
                t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.DESCRIPTION')
              )
            }}
          </p>
        </div>

        <div
          v-if="connection.callbackUrl"
          class="rounded-xl border border-n-weak p-5"
        >
          <p class="text-sm font-medium text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.WEBHOOK_URL') }}
          </p>
          <div class="mt-3 flex items-center gap-3">
            <code
              class="min-w-0 flex-1 break-all rounded-lg bg-n-alpha-1 px-3 py-2.5 text-sm text-n-slate-12"
            >
              {{ connection.callbackUrl }}
            </code>
            <Button
              :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.COPY')"
              icon="i-lucide-copy"
              variant="outline"
              color="slate"
              @click="copyWebhookUrl"
            />
          </div>
        </div>

        <div
          class="flex flex-col divide-y divide-n-weak rounded-xl border border-n-weak px-5"
        >
          <div
            v-for="status in statusRows"
            :key="status.key"
            class="flex items-center justify-between py-4"
          >
            <span class="text-sm font-medium text-n-slate-12">
              {{ status.label }}
            </span>
            <span
              class="flex items-center gap-2 text-sm"
              :class="status.complete ? 'text-n-teal-11' : 'text-n-amber-11'"
            >
              <Icon
                :icon="
                  status.complete ? 'i-lucide-check-circle' : 'i-lucide-clock-3'
                "
              />
              {{
                status.complete
                  ? t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.COMPLETE')
                  : t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.PENDING')
              }}
            </span>
          </div>
        </div>

        <Banner v-if="connectionReady" color="teal">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.VERIFY.SUCCESS') }}
        </Banner>

        <div
          class="flex items-center justify-between border-t border-n-weak pt-5"
        >
          <Button
            :label="
              t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.RETRY_WEBHOOK')
            "
            variant="outline"
            color="slate"
            :is-loading="isLoading"
            :disabled="isLoading"
            @click="retryWebhookSetup"
          />
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.ACTIONS.CONTINUE')"
            trailing-icon
            icon="i-lucide-arrow-right"
            :disabled="isLoading"
            @click="continueToAgents"
          />
        </div>
      </section>
    </div>
  </div>
</template>
