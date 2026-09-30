<script setup>
import { reactive, computed, ref, useTemplateRef, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, maxLength } from '@vuelidate/validators';
import CustomToolsAPI from 'dashboard/api/captain/customTools';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ParamRow from './ParamRow.vue';
import AuthConfig from './AuthConfig.vue';
import HeadersConfig from './HeadersConfig.vue';
import ToolFormSection from './ToolFormSection.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit', 'view'].includes(value),
  },
  tool: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const route = useRoute();

const initialState = {
  title: '',
  description: '',
  endpoint_url: '',
  http_method: 'GET',
  request_template: '',
  response_template: '',
  auth_type: 'none',
  auth_config: {},
  headers: {},
  param_schema: [],
};

const state = reactive({ ...initialState });

// Tools installed from a manifest are shown read-only
const isReadOnly = computed(() => props.mode === 'view');

// Populate form when editing or viewing an existing tool
watch(
  () => props.tool,
  newTool => {
    if (props.mode !== 'create' && newTool && newTool.id) {
      state.title = newTool.title || '';
      state.description = newTool.description || '';
      state.endpoint_url = newTool.endpoint_url || '';
      state.http_method = newTool.http_method || 'GET';
      state.request_template = newTool.request_template || '';
      state.response_template = newTool.response_template || '';
      state.auth_type = newTool.auth_type || 'none';
      state.auth_config = newTool.auth_config || {};
      state.headers = newTool.headers || {};
      state.param_schema = newTool.param_schema || [];
    }
  },
  { immediate: true }
);

const DEFAULT_PARAM = {
  name: '',
  type: 'string',
  description: '',
  required: false,
};

// OpenAI enforces a 64-char limit on function names. The backend slug is
// "custom_" (7 chars) + parameterized title, so cap the title conservatively.
const MAX_TOOL_NAME_LENGTH = 55;

const validationRules = {
  title: { required, maxLength: maxLength(MAX_TOOL_NAME_LENGTH) },
  endpoint_url: { required },
  http_method: { required },
  auth_type: { required },
};

const HTTP_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
const httpMethodOptions = HTTP_METHODS.map(method => ({
  value: method,
  label: method,
}));

const authTypeOptions = computed(() => [
  { value: 'none', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.NONE') },
  { value: 'bearer', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BEARER') },
  { value: 'basic', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BASIC') },
  {
    value: 'api_key',
    label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.API_KEY'),
  },
]);

// Read-only section headers can't be clicked, so view mode starts with every section open
const openSections = reactive({
  headers: isReadOnly.value,
  params: isReadOnly.value,
  templates: isReadOnly.value,
});

const sectionSummaries = computed(() => {
  const headerCount = Object.keys(state.headers).length;
  const paramCount = state.param_schema.length;
  return {
    headers: headerCount ? String(headerCount) : '',
    params: paramCount ? String(paramCount) : '',
  };
});

const hasRequestBody = computed(() => state.http_method !== 'GET');

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = (field, errorKey) => {
  if (!v$.value[field].$error) return '';

  const failedRule = v$.value[field].$errors[0]?.$validator;
  if (failedRule === 'maxLength') {
    return t(`CAPTAIN.CUSTOM_TOOLS.FORM.${errorKey}.MAX_LENGTH_ERROR`, {
      max: MAX_TOOL_NAME_LENGTH,
    });
  }
  return t(`CAPTAIN.CUSTOM_TOOLS.FORM.${errorKey}.ERROR`);
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  endpoint_url: getErrorMessage('endpoint_url', 'ENDPOINT_URL'),
}));

const paramsRef = useTemplateRef('paramsRef');
const headersRef = useTemplateRef('headersRef');

const isParamsValid = () => {
  if (!paramsRef.value || paramsRef.value.length === 0) {
    return true;
  }
  return paramsRef.value.every(param => param.validate());
};

const removeParam = index => {
  state.param_schema.splice(index, 1);
};

const addParam = () => {
  state.param_schema.push({ ...DEFAULT_PARAM });
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  const isHeadersValid = headersRef.value.validate();
  const areParamsValid = isParamsValid();
  if (!isHeadersValid) openSections.headers = true;
  if (!areParamsValid) openSections.params = true;
  if (!isFormValid || !areParamsValid || !isHeadersValid) {
    return;
  }

  emit('submit', state);
};

const isTesting = ref(false);
const testResult = ref(null);
const isTestDisabled = computed(
  () => state.endpoint_url.includes('{{') || !!state.request_template
);

const handleTest = async () => {
  if (!state.endpoint_url) return;
  // Invalid rows are dropped or merged when building headers, so the test would not match what Save accepts
  if (!headersRef.value.validate()) {
    openSections.headers = true;
    return;
  }

  isTesting.value = true;
  testResult.value = null;
  try {
    const { data } = await CustomToolsAPI.test({
      ...state,
      assistantId: route.params.assistantId,
    });
    const isOk = data.status >= 200 && data.status < 300;
    testResult.value = { success: isOk, status: data.status };
  } catch (e) {
    const message =
      e.response?.data?.error || t('CAPTAIN.CUSTOM_TOOLS.TEST.ERROR');
    testResult.value = { success: false, message };
  } finally {
    isTesting.value = false;
  }
};
</script>

<template>
  <form
    id="custom-tool-form"
    class="flex flex-col gap-4"
    @submit.prevent="handleSubmit"
  >
    <!-- Disables every field and button inside for read-only (view) mode; contents keeps the form's layout -->
    <fieldset :disabled="isReadOnly" class="contents">
      <Input
        v-model="state.title"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.TITLE.LABEL')"
        :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.TITLE.PLACEHOLDER')"
        :message="formErrors.title"
        :message-type="formErrors.title ? 'error' : 'info'"
      />

      <TextArea
        v-model="state.description"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.DESCRIPTION.LABEL')"
        :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.DESCRIPTION.PLACEHOLDER')"
        auto-height
        min-height="2.5rem"
      />

      <div class="flex gap-2">
        <div class="flex flex-col gap-1 w-32">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.HTTP_METHOD.LABEL') }}
          </label>
          <ComboBox
            v-model="state.http_method"
            :options="httpMethodOptions"
            class="[&>div>button]:bg-n-alpha-black2 [&_li]:font-mono [&_button]:font-mono [&>div>button]:outline-offset-[-1px]"
          />
        </div>
        <Input
          v-model="state.endpoint_url"
          :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.ENDPOINT_URL.LABEL')"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.ENDPOINT_URL.PLACEHOLDER')"
          :message="formErrors.endpoint_url"
          :message-type="formErrors.endpoint_url ? 'error' : 'info'"
          class="flex-1"
        />
      </div>

      <div class="flex flex-col gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPE.LABEL') }}
        </label>
        <ComboBox
          v-model="state.auth_type"
          :options="authTypeOptions"
          class="[&>div>button]:bg-n-alpha-black2"
        />
      </div>

      <AuthConfig
        v-model:auth-config="state.auth_config"
        :auth-type="state.auth_type"
      />

      <div class="flex flex-col">
        <ToolFormSection
          v-model:open="openSections.headers"
          :title="t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.LABEL')"
          :summary="sectionSummaries.headers"
        >
          <HeadersConfig ref="headersRef" v-model:headers="state.headers" />
        </ToolFormSection>

        <ToolFormSection
          v-model:open="openSections.params"
          :title="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.LABEL')"
          :summary="sectionSummaries.params"
        >
          <p class="text-xs text-n-slate-11">
            {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.HELP_TEXT') }}
          </p>
          <ul v-if="state.param_schema.length > 0" class="grid gap-2 list-none">
            <ParamRow
              v-for="(param, index) in state.param_schema"
              :key="index"
              ref="paramsRef"
              v-model:name="param.name"
              v-model:type="param.type"
              v-model:description="param.description"
              v-model:required="param.required"
              @remove="removeParam(index)"
            />
          </ul>
          <Button
            type="button"
            sm
            ghost
            blue
            icon="i-lucide-plus"
            :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.ADD_PARAMETER')"
            @click="addParam"
          />
        </ToolFormSection>

        <ToolFormSection
          v-model:open="openSections.templates"
          :title="
            hasRequestBody
              ? t('CAPTAIN.CUSTOM_TOOLS.FORM.SECTIONS.TEMPLATES')
              : t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.LABEL')
          "
          class="border-b"
        >
          <p class="text-xs text-n-slate-11">
            {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.SECTIONS.TEMPLATES_HELP_TEXT') }}
          </p>
          <TextArea
            v-if="hasRequestBody"
            v-model="state.request_template"
            :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.LABEL')"
            :placeholder="
              t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.PLACEHOLDER')
            "
            :rows="4"
            class="[&_textarea]:font-mono"
          />

          <TextArea
            v-model="state.response_template"
            :label="
              hasRequestBody
                ? t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.LABEL')
                : ''
            "
            :placeholder="
              t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.PLACEHOLDER')
            "
            :rows="4"
            class="[&_textarea]:font-mono"
          />
        </ToolFormSection>
      </div>

      <div class="flex flex-col gap-2">
        <Button
          type="button"
          variant="faded"
          color="slate"
          icon="i-lucide-play"
          :label="t('CAPTAIN.CUSTOM_TOOLS.TEST.BUTTON')"
          :is-loading="isTesting"
          :disabled="isTesting || !state.endpoint_url || isTestDisabled"
          @click="handleTest"
        />
        <p v-if="isTestDisabled" class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.TEST.DISABLED_HINT') }}
        </p>
        <div
          v-if="testResult"
          class="flex items-center gap-2 px-3 py-2 text-xs rounded-lg"
          :class="
            testResult.success
              ? 'bg-n-teal-2 text-n-teal-11'
              : 'bg-n-ruby-2 text-n-ruby-11'
          "
        >
          <span
            :class="
              testResult.success ? 'i-lucide-check-circle' : 'i-lucide-x-circle'
            "
            class="size-3.5 shrink-0"
          />
          {{
            testResult.status
              ? t('CAPTAIN.CUSTOM_TOOLS.TEST.SUCCESS', {
                  status: testResult.status,
                })
              : testResult.message
          }}
        </div>
      </div>
    </fieldset>
  </form>
</template>
