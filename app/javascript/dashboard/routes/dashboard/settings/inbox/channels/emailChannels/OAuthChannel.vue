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

    <div v-else class="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-8">
      <div class="lg:col-span-2">
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
        class="lg:col-span-1 flex flex-col gap-4 p-4 h-fit rounded-lg bg-n-alpha-1 border border-n-weak"
      >
        <h3 id="oauth-guide-title" class="text-sm font-medium text-n-slate-12">
          {{ tk('GUIDE_TITLE') }}
        </h3>

        <ul
          class="list-disc list-inside flex flex-col gap-1 text-sm text-n-slate-11"
        >
          <li>{{ tk('GUIDE_CAPABILITY_INBOX') }}</li>
          <li>
            {{
              isMicrosoft
                ? tk('GUIDE_CAPABILITY_OUTBOX_MICROSOFT')
                : tk('GUIDE_CAPABILITY_OUTBOX_GOOGLE')
            }}
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

        <div class="flex flex-col gap-1">
          <h4 class="text-xs font-medium text-n-slate-12">
            {{ tk('GUIDE_NEXT_STEPS_TITLE') }}
          </h4>
          <ol
            class="list-decimal list-inside flex flex-col gap-1 text-sm text-n-slate-11"
          >
            <li>{{ tk('GUIDE_NEXT_STEP_1') }}</li>
            <li>{{ tk('GUIDE_NEXT_STEP_2') }}</li>
            <li>{{ tk('GUIDE_NEXT_STEP_3') }}</li>
          </ol>
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
      </aside>
    </div>
  </div>
</template>
