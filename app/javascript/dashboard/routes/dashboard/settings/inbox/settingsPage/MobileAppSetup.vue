<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import SdkAppsAPI from 'dashboard/api/sdkApps';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import HmacSecretKey from './components/HmacSecretKey.vue';
import Code from 'dashboard/components/Code.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: { type: Object, required: true },
  section: { type: String, default: 'setup' },
});
const appId = ref('');
const activeTab = computed(() => props.section);
const { t } = useI18n();
const form = reactive({
  bundle_id: '',
  team_id: '',
  key_id: '',
});
const privateKey = ref('');
const fileInput = ref(null);
const configured = ref(false);
const platform = ref('ios');
const platformTabs = computed(() => [
  { key: 'ios', label: t('INBOX_MGMT.SDK_APPS.IOS') },
  { key: 'android', label: t('INBOX_MGMT.SDK_APPS.ANDROID.TITLE') },
]);
const androidEnabled = ref(false);
const androidConfigured = ref(false);
const serviceAccount = ref('');
const androidFileInput = ref(null);
const androidForm = reactive({ package_name: '', project_id: '' });
const iosEnabled = ref(false);
const iosConfigured = ref(false);
const integrationCode = computed(
  () => `import Foundation
import SwiftUI
import ChatwootSDK

let client = ChatwootClient(configuration: .init(
    baseURL: URL(string: ${JSON.stringify(window.location.origin)})!,
    sdkAppID: ${JSON.stringify(appId.value)}
))

ChatwootView(client: client)`
);
const androidCode = computed(
  () => `val client = ChatwootClient(
    context = applicationContext,
    baseUrl = ${JSON.stringify(window.location.origin)},
    sdkAppId = ${JSON.stringify(appId.value)}
)
Chatwoot.showSupport(this, client)`
);
const loading = ref(true);
const loadFailed = ref(false);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const pushFields = ['bundle_id', 'team_id', 'key_id'];

function reportError(exception) {
  error.value =
    exception.response?.data?.error ||
    exception.response?.data?.message ||
    t('INBOX_MGMT.SDK_APPS.ERROR');
}

async function load() {
  loading.value = true;
  loadFailed.value = false;
  privateKey.value = '';
  serviceAccount.value = '';
  notice.value = '';
  error.value = '';
  try {
    const { data: app } = await SdkAppsAPI.show(props.inbox.id);
    appId.value = app.app_id;
    configured.value = true;
    androidEnabled.value = app?.android_configuration?.enabled ?? false;
    androidConfigured.value = !!app?.android_configuration;
    androidForm.package_name = app?.android_configuration?.package_name || '';
    androidForm.project_id = app?.android_configuration?.project_id || '';
    iosEnabled.value = app?.ios_configuration?.enabled ?? false;
    iosConfigured.value = !!app?.ios_configuration;
    pushFields.forEach(field => {
      form[field] = app?.ios_configuration?.[field] || '';
    });
  } catch (exception) {
    loadFailed.value = true;
    reportError(exception);
  } finally {
    loading.value = false;
  }
}

async function readKey(event) {
  privateKey.value = '';
  error.value = '';
  const file = event.target.files[0];
  if (!file) return;
  if (file.size > 8192) {
    error.value = t('INBOX_MGMT.SDK_APPS.KEY_TOO_LARGE');
    event.target.value = '';
    return;
  }
  privateKey.value = await file.text();
}

async function readServiceAccount(event) {
  serviceAccount.value = '';
  error.value = '';
  const file = event.target.files[0];
  if (!file) return;
  if (file.size > 16384) {
    error.value = t('INBOX_MGMT.SDK_APPS.ANDROID.KEY_TOO_LARGE');
    event.target.value = '';
    return;
  }
  serviceAccount.value = await file.text();
}

async function save() {
  const savingTab = activeTab.value;
  busy.value = true;
  error.value = '';
  notice.value = '';
  try {
    const attributes =
      savingTab === 'push'
        ? {
            ...(platform.value === 'android'
              ? {
                  android_configuration:
                    androidEnabled.value || androidConfigured.value
                      ? {
                          enabled: androidEnabled.value,
                          ...androidForm,
                          ...(serviceAccount.value
                            ? { service_account: serviceAccount.value }
                            : {}),
                        }
                      : null,
                }
              : {
                  ios_configuration:
                    iosEnabled.value || iosConfigured.value
                      ? {
                          enabled: iosEnabled.value,
                          bundle_id: form.bundle_id,
                          team_id: form.team_id,
                          key_id: form.key_id,
                          ...(privateKey.value
                            ? { private_key: privateKey.value }
                            : {}),
                        }
                      : null,
                }),
          }
        : {};
    const { data } = await SdkAppsAPI.update(props.inbox.id, {
      sdk_app: attributes,
    });
    appId.value = data.app_id;
    configured.value = true;
    if (savingTab === 'push') privateKey.value = '';
    if (savingTab === 'push' && fileInput.value) fileInput.value.value = '';
    iosConfigured.value = !!data.ios_configuration;
    androidConfigured.value = !!data.android_configuration;
    serviceAccount.value = '';
    if (androidFileInput.value) androidFileInput.value.value = '';
    notice.value = t('INBOX_MGMT.SDK_APPS.SAVED');
  } catch (exception) {
    reportError(exception);
  } finally {
    busy.value = false;
  }
}

onMounted(load);
watch(() => props.inbox.id, load);
</script>

<template>
  <section class="flex flex-col w-full gap-4 py-4">
    <p v-if="loading" class="text-n-slate-11">
      {{ t('INBOX_MGMT.SDK_APPS.LOADING') }}
    </p>
    <p v-if="error" role="alert" class="text-n-ruby-9">{{ error }}</p>
    <p v-if="notice" role="status" class="text-n-teal-10">{{ notice }}</p>
    <div
      v-if="configured && !loading && !loadFailed"
      class="flex items-center gap-3"
    >
      <TabBar
        :tabs="platformTabs"
        :initial-active-tab="platform === 'ios' ? 0 : 1"
        @tab-changed="platform = $event.key"
      />
    </div>
    <form
      v-if="!loading && !loadFailed && activeTab !== 'setup'"
      class="flex flex-col gap-4 max-w-xl"
      @submit.prevent="save"
    >
      <template v-if="activeTab === 'push' && platform === 'ios'">
        <div class="flex items-center justify-between gap-4">
          <h3 class="text-heading-3 text-n-slate-12">
            {{ t('INBOX_MGMT.SDK_APPS.PUSH_TITLE') }}
          </h3>
          <Switch
            v-model="iosEnabled"
            :aria-label="t('INBOX_MGMT.SDK_APPS.ENABLE_IOS')"
          />
        </div>
        <p class="text-body-small text-n-slate-11">
          {{ t('INBOX_MGMT.SDK_APPS.PUSH_OPTIONAL') }}
        </p>
        <p
          v-if="iosConfigured && !iosEnabled"
          class="text-body-small text-n-ruby-11"
        >
          {{ t('INBOX_MGMT.SDK_APPS.DISABLE_IOS_HELP') }}
        </p>
        <template v-if="iosEnabled || iosConfigured">
          <Input
            v-for="field in pushFields"
            :key="field"
            v-model="form[field]"
            :label="t(`INBOX_MGMT.SDK_APPS.FIELDS.${field.toUpperCase()}`)"
          />
          <label class="flex flex-col gap-2 text-body-main text-n-slate-12">
            {{ t('INBOX_MGMT.SDK_APPS.PRIVATE_KEY') }}
            <input ref="fileInput" type="file" accept=".p8" @change="readKey" />
          </label>
          <p class="text-body-small text-n-slate-11">
            {{
              t(
                iosConfigured
                  ? 'INBOX_MGMT.SDK_APPS.KEY_SAVED'
                  : 'INBOX_MGMT.SDK_APPS.KEY_HELP'
              )
            }}
          </p>
        </template>
      </template>
      <template v-if="activeTab === 'push' && platform === 'android'">
        <div class="flex items-center justify-between gap-4">
          <h3 class="text-heading-3 text-n-slate-12">
            {{ t('INBOX_MGMT.SDK_APPS.ANDROID.PUSH_TITLE') }}
          </h3>
          <Switch
            v-model="androidEnabled"
            :aria-label="t('INBOX_MGMT.SDK_APPS.ANDROID.ENABLE')"
          />
        </div>
        <p class="text-body-small text-n-slate-11">
          {{ t('INBOX_MGMT.SDK_APPS.ANDROID.HELP') }}
        </p>
        <p
          v-if="androidConfigured && !androidEnabled"
          class="text-body-small text-n-ruby-11"
        >
          {{ t('INBOX_MGMT.SDK_APPS.ANDROID.DISABLE_HELP') }}
        </p>
        <template v-if="androidEnabled || androidConfigured">
          <Input
            v-model="androidForm.package_name"
            :label="t('INBOX_MGMT.SDK_APPS.ANDROID.PACKAGE_NAME')"
          />
          <Input
            v-model="androidForm.project_id"
            :label="t('INBOX_MGMT.SDK_APPS.ANDROID.PROJECT_ID')"
          />
          <label class="flex flex-col gap-2 text-body-main text-n-slate-12">
            {{ t('INBOX_MGMT.SDK_APPS.ANDROID.SERVICE_ACCOUNT') }}
            <input
              ref="androidFileInput"
              type="file"
              accept=".json"
              @change="readServiceAccount"
            />
          </label>
          <p v-if="androidConfigured" class="text-body-small text-n-slate-11">
            {{ t('INBOX_MGMT.SDK_APPS.ANDROID.KEY_SAVED') }}
          </p>
        </template>
      </template>
      <Button
        type="submit"
        :is-loading="busy"
        :disabled="busy"
        :label="t('INBOX_MGMT.SDK_APPS.SAVE')"
        class="self-start"
      />
    </form>
    <section
      v-if="appId && !loading && !loadFailed && activeTab === 'setup'"
      class="flex flex-col gap-4 max-w-2xl"
    >
      <div class="flex flex-col gap-2">
        <span class="text-body-small text-n-slate-11">{{
          t('INBOX_MGMT.SDK_APPS.APP_ID')
        }}</span>
        <Code :script="appId" lang="plaintext" />
        <p class="text-body-small text-n-slate-11">
          {{ t('INBOX_MGMT.SDK_APPS.APP_ID_HELP') }}
        </p>
      </div>
      <h2 class="text-heading-3 text-n-slate-12">
        {{ t('INBOX_MGMT.SDK_APPS.INSTALL_STEP') }}
      </h2>
      <p class="text-body-main text-n-slate-11">
        {{
          t(
            platform === 'ios'
              ? 'INBOX_MGMT.SDK_APPS.INSTALL_HELP'
              : 'INBOX_MGMT.SDK_APPS.ANDROID.INSTALL_HELP'
          )
        }}
      </p>
      <Code
        :script="`https://github.com/chatwoot/${platform}-sdk`"
        lang="plaintext"
      />
      <h2 class="text-heading-3 text-n-slate-12">
        {{ t('INBOX_MGMT.SDK_APPS.OPEN_STEP') }}
      </h2>
      <p class="text-body-main text-n-slate-11">
        {{
          platform === 'ios'
            ? t('INBOX_MGMT.SDK_APPS.INIT_HELP')
            : t('INBOX_MGMT.SDK_APPS.ANDROID.INIT_HELP')
        }}
      </p>
      <Code
        :script="platform === 'ios' ? integrationCode : androidCode"
        :lang="platform === 'ios' ? 'swift' : 'kotlin'"
      />
      <details class="group border-t border-n-weak pt-3">
        <summary class="cursor-pointer text-body-main text-n-slate-12">
          {{ t('INBOX_MGMT.SDK_APPS.IDENTITY_TITLE') }}
        </summary>
        <p class="mt-2 text-body-small text-n-slate-11">
          {{ t('INBOX_MGMT.SDK_APPS.IDENTITY_HELP') }}
        </p>
        <HmacSecretKey :inbox="inbox" />
      </details>
      <details class="group border-t border-n-weak pt-3">
        <summary class="cursor-pointer text-body-main text-n-slate-12">
          {{ t('INBOX_MGMT.SDK_APPS.TABS.PUSH') }}
        </summary>
        <p class="mt-2 text-body-small text-n-slate-11">
          {{
            t(
              platform === 'ios'
                ? 'INBOX_MGMT.SDK_APPS.APPLE_HELP'
                : 'INBOX_MGMT.SDK_APPS.ANDROID.HELP'
            )
          }}
        </p>
      </details>
      <a
        :href="`https://github.com/chatwoot/${platform}-sdk#readme`"
        target="_blank"
        rel="noopener noreferrer"
        class="text-n-blue-11 hover:underline"
      >
        {{
          platform === 'ios'
            ? t('INBOX_MGMT.SDK_APPS.DOCS')
            : t('INBOX_MGMT.SDK_APPS.ANDROID.DOCS')
        }}
      </a>
    </section>
  </section>
</template>
