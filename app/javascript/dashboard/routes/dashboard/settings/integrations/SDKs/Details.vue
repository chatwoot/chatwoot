<script setup>
import { computed, onActivated, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import { useI18n } from 'vue-i18n';
import SdkAppsAPI from 'dashboard/api/sdkApps';
import InboxesAPI from 'dashboard/api/inboxes';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Code from 'dashboard/components/Code.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const inboxes = ref([]);
const selectedId = ref(route.params.sdkAppId || null);
const appId = ref('');
const savedApp = ref(null);
const activeTab = ref('setup');
const { t } = useI18n();
const tabs = computed(() => [
  { key: 'setup', label: t('INBOX_MGMT.SDK_APPS.TABS.SETUP') },
  { key: 'settings', label: t('INBOX_MGMT.SDK_APPS.TABS.SETTINGS') },
  { key: 'push', label: t('INBOX_MGMT.SDK_APPS.TABS.PUSH') },
]);
const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);
const connectedInbox = computed(
  () =>
    inboxes.value.find(inbox => inbox.id === savedApp.value?.inbox_id)?.name ||
    ''
);
const form = reactive({
  name: '',
  inbox_id: null,
  bundle_id: '',
  team_id: '',
  key_id: '',
});
const privateKey = ref('');
const fileInput = ref(null);
const configured = ref(false);
const platform = ref('ios');
const androidEnabled = ref(false);
const androidConfigured = ref(false);
const serviceAccount = ref('');
const androidFileInput = ref(null);
const androidForm = reactive({ package_name: '', project_id: '' });
const iosEnabled = ref(false);
const iosConfigured = ref(false);
const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
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

function changeTab(index) {
  activeTab.value = tabs.value[index].key;
  error.value = '';
  notice.value = '';
}

function reportError(exception) {
  error.value =
    exception.response?.data?.error ||
    exception.response?.data?.message ||
    t('INBOX_MGMT.SDK_APPS.ERROR');
}

async function load() {
  selectedId.value = route.params.sdkAppId || null;
  loading.value = true;
  loadFailed.value = false;
  privateKey.value = '';
  serviceAccount.value = '';
  notice.value = '';
  error.value = '';
  try {
    const [appResponse, inboxResponse] = await Promise.all([
      selectedId.value
        ? SdkAppsAPI.show(selectedId.value)
        : Promise.resolve({ data: null }),
      InboxesAPI.get(),
    ]);
    const app = appResponse.data;
    savedApp.value = app;
    activeTab.value = app ? 'setup' : 'settings';
    appId.value = app?.app_id || '';
    configured.value = !!app;
    form.name = app?.name || '';
    androidEnabled.value = !!app?.android_configuration;
    androidConfigured.value = !!app?.android_configuration;
    androidForm.package_name = app?.android_configuration?.package_name || '';
    androidForm.project_id = app?.android_configuration?.project_id || '';
    iosEnabled.value = !!app?.ios_configuration;
    iosConfigured.value = !!app?.ios_configuration;
    pushFields.forEach(field => {
      form[field] = app?.ios_configuration?.[field] || '';
    });
    form.inbox_id = app?.inbox_id || null;
    inboxes.value = inboxResponse.data.payload.filter(
      inbox => inbox.channel_type === 'Channel::WebWidget'
    );
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
            name: savedApp.value.name,
            inbox_id: savedApp.value.inbox_id,
            ...(platform.value === 'android'
              ? {
                  android_configuration: androidEnabled.value
                    ? {
                        ...androidForm,
                        ...(serviceAccount.value
                          ? { service_account: serviceAccount.value }
                          : {}),
                      }
                    : null,
                }
              : {
                  ios_configuration: iosEnabled.value
                    ? {
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
        : { name: form.name, inbox_id: form.inbox_id };
    const { data } = selectedId.value
      ? await SdkAppsAPI.update(selectedId.value, { sdk_app: attributes })
      : await SdkAppsAPI.create({ sdk_app: attributes });
    savedApp.value = data;
    selectedId.value = data.id;
    appId.value = data.app_id;
    configured.value = true;
    if (savingTab === 'push') privateKey.value = '';
    if (savingTab === 'push' && fileInput.value) fileInput.value.value = '';
    iosConfigured.value = !!data.ios_configuration;
    androidConfigured.value = !!data.android_configuration;
    serviceAccount.value = '';
    if (androidFileInput.value) androidFileInput.value.value = '';
    notice.value = t('INBOX_MGMT.SDK_APPS.SAVED');
    if (!route.params.sdkAppId) {
      activeTab.value = 'setup';
      await router.replace({
        name: 'settings_integrations_sdk_details',
        params: { accountId: route.params.accountId, sdkAppId: data.id },
      });
    }
  } catch (exception) {
    reportError(exception);
  } finally {
    busy.value = false;
  }
}

onActivated(load);
</script>

<template>
  <section class="flex flex-col w-full gap-6 py-6">
    <BaseSettingsHeader
      :title="configured ? savedApp.name : t('INBOX_MGMT.SDK_APPS.ADD')"
      :description="
        configured
          ? connectedInbox
          : t('INBOX_MGMT.SDK_APPS.DETAILS_DESCRIPTION')
      "
      :back-button-label="t('INBOX_MGMT.SDK_APPS.TITLE')"
    />
    <woot-tabs
      v-if="configured && !loading && !loadFailed"
      :index="activeTabIndex"
      class="[&_ul]:p-0"
      @change="changeTab"
    >
      <woot-tabs-item
        v-for="(tab, index) in tabs"
        :key="tab.key"
        :index="index"
        :name="tab.label"
        :show-badge="false"
        is-compact
      />
    </woot-tabs>
    <p v-if="loading" class="text-n-slate-11">
      {{ t('INBOX_MGMT.SDK_APPS.LOADING') }}
    </p>
    <p v-if="error" role="alert" class="text-n-ruby-9">{{ error }}</p>
    <p v-if="notice" role="status" class="text-n-teal-10">{{ notice }}</p>
    <div v-if="configured && activeTab !== 'settings'" class="flex gap-2">
      <Button
        :label="t('INBOX_MGMT.SDK_APPS.IOS')"
        :variant="platform === 'ios' ? 'solid' : 'outline'"
        @click="platform = 'ios'"
      />
      <Button
        :label="t('INBOX_MGMT.SDK_APPS.ANDROID.TITLE')"
        :variant="platform === 'android' ? 'solid' : 'outline'"
        @click="platform = 'android'"
      />
    </div>
    <form
      v-if="!loading && !loadFailed && activeTab !== 'setup'"
      class="flex flex-col gap-4 max-w-xl"
      @submit.prevent="save"
    >
      <template v-if="activeTab === 'settings'">
        <h3 class="text-heading-3 text-n-slate-12">
          {{ t('INBOX_MGMT.SDK_APPS.APP_DETAILS') }}
        </h3>
        <Input
          v-model="form.name"
          :label="t('INBOX_MGMT.SDK_APPS.FIELDS.NAME')"
        />
        <div class="flex flex-col gap-1">
          <label
            for="sdk-inbox"
            class="mb-0.5 text-sm font-medium text-n-slate-12"
          >
            {{ t('INBOX_MGMT.SDK_APPS.INBOX') }}
          </label>
          <ComboBox
            id="sdk-inbox"
            v-model="form.inbox_id"
            :options="inboxOptions"
            :placeholder="t('INBOX_MGMT.SDK_APPS.SELECT_INBOX')"
            class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
          />
        </div>
        <p class="text-body-small text-n-slate-11">
          {{ t('INBOX_MGMT.SDK_APPS.INBOX_HELP') }}
        </p>
      </template>
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
        <template v-if="iosEnabled">
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
        <template v-if="androidEnabled">
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
      <h2 class="text-heading-2 text-n-slate-12">
        {{
          platform === 'ios'
            ? t('INBOX_MGMT.SDK_APPS.GET_STARTED')
            : t('INBOX_MGMT.SDK_APPS.ANDROID.GET_STARTED')
        }}
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
