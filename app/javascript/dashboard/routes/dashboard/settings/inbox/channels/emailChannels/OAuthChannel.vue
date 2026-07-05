<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import microsoftClient from 'dashboard/api/channel/microsoftClient';
import googleClient from 'dashboard/api/channel/googleClient';
import EmailOauthAppAPI from 'dashboard/api/channel/emailOauthApp';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

import { useAlert } from 'dashboard/composables';

const props = defineProps({
  provider: {
    type: String,
    required: true,
    validate: value => ['microsoft', 'google'].includes(value),
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  submitButtonText: {
    type: String,
    required: true,
  },
  errorMessage: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
// eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
const tk = key => t(`INBOX_MGMT.OAUTH_CREDENTIALS.${key}`);

const isLoadingConfig = ref(true);
const isSaving = ref(false);
const isRequestingAuthorization = ref(false);

const configured = ref(false);
const source = ref(null);
const callbackUrl = ref('');
const clientId = ref('');
const clientSecret = ref('');
const tenantId = ref('');

const isMicrosoft = computed(() => props.provider === 'microsoft');
const client = computed(() =>
  isMicrosoft.value ? microsoftClient : googleClient
);
const canSave = computed(
  () => clientId.value.trim() !== '' && clientSecret.value.trim() !== ''
);

const appRegistrationUrl = computed(() =>
  isMicrosoft.value
    ? 'https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade'
    : 'https://console.cloud.google.com/apis/credentials'
);
const calendarSetupUrl = computed(() =>
  isMicrosoft.value
    ? 'https://learn.microsoft.com/graph/permissions-reference'
    : 'https://console.cloud.google.com/apis/library/calendar-json.googleapis.com'
);
const docsUrl = 'https://chatwoot.help/hc/handbook';

onMounted(async () => {
  try {
    const { data } = await EmailOauthAppAPI.get(props.provider);
    configured.value = data.configured;
    source.value = data.source;
    callbackUrl.value = data.callback_url;
    clientId.value = data.client_id || '';
    tenantId.value = data.tenant_id || '';
  } catch (error) {
    configured.value = false;
  } finally {
    isLoadingConfig.value = false;
  }
});

const copyCallback = async () => {
  try {
    await navigator.clipboard.writeText(callbackUrl.value);
    useAlert(tk('COPIED'));
  } catch (error) {
    useAlert(callbackUrl.value);
  }
};

const saveCredentials = async () => {
  if (!canSave.value) return;
  isSaving.value = true;
  try {
    await EmailOauthAppAPI.update(props.provider, {
      clientId: clientId.value.trim(),
      clientSecret: clientSecret.value.trim(),
      tenantId: isMicrosoft.value ? tenantId.value.trim() : undefined,
    });
    configured.value = true;
    source.value = 'account';
    clientSecret.value = '';
  } catch (error) {
    useAlert(tk('SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const requestAuthorization = async () => {
  try {
    isRequestingAuthorization.value = true;
    const {
      data: { url },
    } = await client.value.generateAuthorization();
    window.location.href = url;
  } catch (error) {
    useAlert(props.errorMessage);
  } finally {
    isRequestingAuthorization.value = false;
  }
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <SettingsSubPageHeader
      :header-title="title"
      :header-content="description"
    />

    <div v-if="isLoadingConfig" class="mt-6 text-sm text-n-slate-11">
      {{ tk('LOADING') }}
    </div>

    <div v-else class="mt-6 flex flex-col lg:flex-row gap-8 items-start">
      <div class="w-full lg:w-[340px] lg:flex-none">
        <form
          v-if="!configured"
          class="flex flex-col gap-4 max-w-xl"
          @submit.prevent="saveCredentials"
        >
          <p class="text-sm text-n-slate-11">
            {{ isMicrosoft ? tk('INTRO_MICROSOFT') : tk('INTRO_GOOGLE') }}
          </p>

          <div
            v-if="callbackUrl"
            class="flex flex-col gap-1 p-3 rounded-lg bg-n-alpha-1 border border-n-weak"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ tk('CALLBACK_LABEL') }}
            </label>
            <div class="flex items-center gap-2">
              <code class="flex-1 text-xs break-all text-n-slate-12">{{
                callbackUrl
              }}</code>
              <NextButton
                type="button"
                sm
                faded
                slate
                :label="tk('COPY')"
                @click="copyCallback"
              />
            </div>
          </div>

          <label>
            {{
              isMicrosoft ? tk('CLIENT_ID_MICROSOFT') : tk('CLIENT_ID_GOOGLE')
            }}
            <input
              v-model="clientId"
              type="text"
              :placeholder="
                isMicrosoft
                  ? tk('CLIENT_ID_MICROSOFT_PH')
                  : tk('CLIENT_ID_GOOGLE_PH')
              "
            />
          </label>

          <label>
            {{
              isMicrosoft
                ? tk('CLIENT_SECRET_MICROSOFT')
                : tk('CLIENT_SECRET_GOOGLE')
            }}
            <input
              v-model="clientSecret"
              type="password"
              autocomplete="off"
              :placeholder="tk('CLIENT_SECRET_PH')"
            />
          </label>

          <label v-if="isMicrosoft">
            {{ tk('TENANT_ID_MICROSOFT') }}
            <input
              v-model="tenantId"
              type="text"
              :placeholder="tk('TENANT_ID_MICROSOFT_PH')"
            />
            <span class="text-xs text-n-slate-11">
              {{ tk('TENANT_ID_MICROSOFT_HINT') }}
            </span>
          </label>

          <div>
            <NextButton
              :is-loading="isSaving"
              :disabled="!canSave"
              type="submit"
              solid
              blue
              :label="tk('SAVE_AND_CONTINUE')"
            />
          </div>
        </form>

        <form v-else @submit.prevent="requestAuthorization">
          <p v-if="source === 'account'" class="text-xs text-n-slate-11 mb-3">
            {{ tk('USING_ACCOUNT_APP') }}
            <button
              type="button"
              class="underline text-n-brand"
              @click="configured = false"
            >
              {{ tk('EDIT_APP') }}
            </button>
          </p>
          <NextButton
            :is-loading="isRequestingAuthorization"
            type="submit"
            solid
            blue
            :label="submitButtonText"
          />
        </form>
      </div>

      <aside
        aria-labelledby="oauth-guide-title"
        class="w-full lg:flex-1 flex flex-col gap-5 p-5 h-fit rounded-lg bg-n-alpha-1 border border-n-weak"
      >
        <h3 id="oauth-guide-title" class="text-sm font-medium text-n-slate-12">
          {{ tk('GUIDE_TITLE') }}
        </h3>

        <ul class="flex flex-col gap-2.5 text-sm text-n-slate-11">
          <li>{{ tk('GUIDE_CAPABILITY_INBOX') }}</li>
          <li>
            {{
              isMicrosoft
                ? tk('GUIDE_CAPABILITY_OUTBOX_MICROSOFT')
                : tk('GUIDE_CAPABILITY_OUTBOX_GOOGLE')
            }}
          </li>
          <li class="flex flex-col gap-0.5">
            <span class="flex items-center gap-2">
              {{ tk('GUIDE_CAPABILITY_CALENDAR') }}
              <span
                class="px-1.5 py-0.5 text-xs font-semibold uppercase rounded text-n-amber-11 bg-n-amber-3"
              >
                {{ tk('GUIDE_BADGE_REQUIRED') }}
              </span>
            </span>
            <span class="text-xs text-n-slate-10">
              {{ tk('GUIDE_CAPABILITY_CALENDAR_DESC') }}
            </span>
          </li>
        </ul>

        <div class="flex flex-col gap-1">
          <h4 class="text-xs font-medium text-n-slate-12">
            {{ tk('GUIDE_AFTER_AUTH_TITLE') }}
          </h4>
          <p class="text-sm text-n-slate-11">
            {{ tk('GUIDE_AFTER_AUTH_TEXT') }}
          </p>
        </div>

        <div class="flex flex-col gap-2">
          <h4 class="text-xs font-medium text-n-slate-12">
            {{ tk('GUIDE_STEPS_TITLE') }}
          </h4>
          <ol
            class="list-decimal list-inside flex flex-col gap-2 text-sm text-n-slate-11 marker:text-n-slate-10"
          >
            <li>
              {{ tk('GUIDE_STEP_APP') }} — {{ tk('GUIDE_STEP_APP_DESC') }}
              <a
                :href="appRegistrationUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="text-n-brand hover:underline"
              >
                {{
                  isMicrosoft
                    ? tk('GUIDE_STEP_APP_LINK_MICROSOFT')
                    : tk('GUIDE_STEP_APP_LINK_GOOGLE')
                }}
              </a>
            </li>
            <li>
              <span class="inline-flex items-center gap-2">
                {{ tk('GUIDE_STEP_CALENDAR') }}
                <span
                  class="px-1.5 py-0.5 text-xs font-semibold uppercase rounded text-n-amber-11 bg-n-amber-3"
                >
                  {{ tk('GUIDE_BADGE_MANDATORY') }}
                </span>
              </span>
              —
              {{
                isMicrosoft
                  ? tk('GUIDE_STEP_CALENDAR_MICROSOFT')
                  : tk('GUIDE_STEP_CALENDAR_GOOGLE')
              }}
              <a
                :href="calendarSetupUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="text-n-brand hover:underline"
              >
                {{
                  isMicrosoft
                    ? tk('GUIDE_STEP_CALENDAR_LINK_MICROSOFT')
                    : tk('GUIDE_STEP_CALENDAR_LINK_GOOGLE')
                }}
              </a>
            </li>
            <li>
              {{ tk('GUIDE_STEP_REDIRECT') }} —
              {{ tk('GUIDE_STEP_REDIRECT_DESC') }}
            </li>
            <li>
              {{ tk('GUIDE_STEP_SAVE') }} — {{ tk('GUIDE_STEP_SAVE_DESC') }}
            </li>
          </ol>
        </div>

        <div
          class="flex flex-col gap-1 p-3 rounded-lg bg-n-amber-2 border border-n-amber-5"
        >
          <h4 class="text-xs font-medium text-n-amber-11">
            {{ tk('GUIDE_REQUIREMENT_TITLE') }}
          </h4>
          <p class="text-sm text-n-slate-11">
            {{
              isMicrosoft
                ? tk('GUIDE_REQUIREMENT_MICROSOFT')
                : tk('GUIDE_REQUIREMENT_GOOGLE')
            }}
          </p>
        </div>

        <details class="text-sm text-n-slate-11">
          <summary class="cursor-pointer text-xs font-medium text-n-slate-12">
            {{ tk('GUIDE_SCOPES_EXPAND') }}
          </summary>
          <p class="mt-2 break-words">
            {{
              isMicrosoft
                ? tk('GUIDE_SCOPES_MICROSOFT')
                : tk('GUIDE_SCOPES_GOOGLE')
            }}
          </p>
        </details>

        <a
          :href="docsUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm text-n-brand hover:underline"
        >
          {{ tk('GUIDE_DOCS_LINK') }}
        </a>
      </aside>
    </div>
  </div>
</template>
