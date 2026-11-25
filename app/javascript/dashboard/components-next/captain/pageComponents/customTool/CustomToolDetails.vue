<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import Switch from 'dashboard/components-next/switch/Switch.vue';
import ToolFormSection from './ToolFormSection.vue';

const props = defineProps({
  tool: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const { isAdmin } = useAdmin();

const authTypeLabel = computed(
  () =>
    ({
      bearer: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BEARER'),
      basic: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BASIC'),
      api_key: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.API_KEY'),
    })[props.tool.auth_type] || t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.NONE')
);

const paramTypeLabels = computed(() => ({
  string: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.STRING'),
  number: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.NUMBER'),
  boolean: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.BOOLEAN'),
  array: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.ARRAY'),
  object: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.OBJECT'),
}));

const params = computed(() => props.tool.param_schema || []);
const headers = computed(() => Object.entries(props.tool.headers || {}));
const hasRequestBody = computed(() => props.tool.http_method !== 'GET');
const showRequest = ref(false);
const usesVerifiedEmail = computed(() =>
  params.value.some(param => param.source === 'verified.email')
);

// Admins can change email verification on an installed tool. It saves as soon as it changes.
const canChangeVerification = computed(
  () =>
    isAdmin.value && !!props.tool.source_metadata && !usesVerifiedEmail.value
);

const verificationSetting = ref(false);
const isSaving = ref(false);
watch(
  () => props.tool.settings?.requires_email_verification,
  value => {
    verificationSetting.value = value === true;
  },
  { immediate: true }
);

const saveVerification = async value => {
  isSaving.value = true;
  try {
    await store.dispatch('captainCustomTools/update', {
      id: props.tool.id,
      settings: { requires_email_verification: value },
      assistantId: route.params.assistantId,
    });
    useAlert(t('CAPTAIN.CUSTOM_TOOLS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    verificationSetting.value = !value;
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.CUSTOM_TOOLS.EDIT.ERROR_MESSAGE')
    );
  } finally {
    isSaving.value = false;
  }
};

const requiresEmailVerification = computed({
  get: () => usesVerifiedEmail.value || verificationSetting.value,
  set: value => {
    verificationSetting.value = value;
    saveVerification(value);
  },
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex flex-col gap-2">
      <p v-if="tool.description" class="mb-0 text-sm text-n-slate-12">
        {{ tool.description }}
      </p>
      <p
        v-if="tool.source_metadata"
        class="flex items-center gap-1.5 mb-0 text-xs text-n-slate-11"
      >
        <i class="i-lucide-lock size-3 shrink-0" />
        {{ t('CAPTAIN.CUSTOM_TOOLS.VIEW.INSTALLED_NOTE') }}
      </p>
    </div>

    <label
      class="flex items-start justify-between gap-3 px-4 py-3 rounded-xl outline outline-1 outline-n-weak"
    >
      <span class="flex flex-col gap-0.5">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.EMAIL_VERIFICATION.LABEL') }}
        </span>
        <span class="text-sm text-n-slate-11">
          {{
            usesVerifiedEmail
              ? t('CAPTAIN.CUSTOM_TOOLS.FORM.EMAIL_VERIFICATION.IMPLIED')
              : t('CAPTAIN.CUSTOM_TOOLS.FORM.EMAIL_VERIFICATION.DESCRIPTION')
          }}
        </span>
      </span>
      <Switch
        v-model="requiresEmailVerification"
        :disabled="!canChangeVerification || isSaving"
        class="shrink-0"
      />
    </label>

    <section class="flex flex-col gap-2">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPE.LABEL') }}
      </h4>
      <div
        class="flex items-center gap-2 px-4 py-3 text-sm rounded-xl outline outline-1 outline-n-weak text-n-slate-12"
      >
        <i class="i-lucide-key-round size-3.5 shrink-0 text-n-slate-11" />
        {{ authTypeLabel }}
      </div>
    </section>

    <section v-if="params.length" class="flex flex-col gap-2">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.LABEL') }}
      </h4>
      <ul
        class="m-0 list-none divide-y rounded-xl outline outline-1 outline-n-weak divide-n-weak"
      >
        <li
          v-for="param in params"
          :key="param.name"
          class="flex flex-col gap-1 px-4 py-3"
        >
          <div class="flex flex-wrap items-center gap-2">
            <code class="text-sm font-medium font-mono text-n-slate-12">
              {{ param.name }}
            </code>
            <span v-if="param.source" class="text-xs text-n-slate-11">
              <i class="i-lucide-lock size-3 align-[-0.125rem]" />
              {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.EMAIL') }}
            </span>
            <template v-else>
              <span class="text-xs text-n-slate-11">
                {{ paramTypeLabels[param.type] }}
              </span>
              <span v-if="param.required" class="text-xs text-n-slate-10">
                {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_REQUIRED.LABEL') }}
              </span>
            </template>
          </div>
          <p
            v-if="param.source || param.description"
            class="mb-0 text-xs text-n-slate-11"
          >
            {{
              param.source
                ? t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.HELP')
                : param.description
            }}
          </p>
        </li>
      </ul>
    </section>

    <ToolFormSection
      v-model:open="showRequest"
      :title="t('CAPTAIN.CUSTOM_TOOLS.VIEW.REQUEST')"
      class="border-b"
    >
      <div class="flex flex-col gap-1.5">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.ENDPOINT_URL.LABEL') }}
        </span>
        <div
          dir="ltr"
          class="flex items-start gap-2 p-3 rounded-lg bg-n-alpha-black2"
        >
          <span
            class="px-1.5 text-xs font-medium leading-5 rounded shrink-0 font-mono bg-n-alpha-2 text-n-slate-12"
          >
            {{ tool.http_method }}
          </span>
          <code
            class="min-w-0 text-xs leading-5 break-words font-mono text-n-slate-12"
          >
            {{ tool.endpoint_url }}
          </code>
        </div>
      </div>

      <div v-if="headers.length" class="flex flex-col gap-1.5">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.LABEL') }}
        </span>
        <ul
          dir="ltr"
          class="m-0 list-none divide-y rounded-lg outline outline-1 outline-n-weak divide-n-weak"
        >
          <li
            v-for="[name, value] in headers"
            :key="name"
            class="grid grid-cols-3 gap-3 px-3 py-2 text-xs font-mono"
          >
            <span class="break-words text-n-slate-11">{{ name }}</span>
            <span class="col-span-2 min-w-0 break-words text-n-slate-12">
              {{ value }}
            </span>
          </li>
        </ul>
      </div>

      <div
        v-if="hasRequestBody && tool.request_template"
        class="flex flex-col gap-1.5"
      >
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.LABEL') }}
        </span>
        <pre
          dir="ltr"
          class="p-3 m-0 text-xs leading-5 whitespace-pre-wrap break-words rounded-lg font-mono bg-n-alpha-black2 text-n-slate-12"
        ><code>{{ tool.request_template }}</code></pre>
      </div>

      <div v-if="tool.response_template" class="flex flex-col gap-1.5">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.LABEL') }}
        </span>
        <pre
          dir="ltr"
          class="p-3 m-0 text-xs leading-5 whitespace-pre-wrap break-words rounded-lg font-mono bg-n-alpha-black2 text-n-slate-12"
        ><code>{{ tool.response_template }}</code></pre>
      </div>
    </ToolFormSection>
  </div>
</template>
