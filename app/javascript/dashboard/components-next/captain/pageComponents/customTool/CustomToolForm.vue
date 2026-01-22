<script setup>
import { reactive, computed, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ParamRow from './ParamRow.vue';
import AuthConfig from './AuthConfig.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  tool: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainCustomTools/getUIFlags'),
};

const initialState = {
  title: '',
  description: '',
  endpoint_url: '',
  http_method: 'GET',
  request_template: '',
  response_template: '',
  auth_type: 'none',
  auth_config: {},
  param_schema: [],
};

const state = reactive({ ...initialState });

// Populate form when in edit mode
watch(
  () => props.tool,
  newTool => {
    if (props.mode === 'edit' && newTool && newTool.id) {
      state.title = newTool.title || '';
      state.description = newTool.description || '';
      state.endpoint_url = newTool.endpoint_url || '';
      state.http_method = newTool.http_method || 'GET';
      state.request_template = newTool.request_template || '';
      state.response_template = newTool.response_template || '';
      state.auth_type = newTool.auth_type || 'none';
      state.auth_config = newTool.auth_config || {};
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

const validationRules = {
  title: { required },
  endpoint_url: { required },
  http_method: { required },
  auth_type: { required },
};

const httpMethodOptions = computed(() => [
  { value: 'GET', label: 'GET' },
  { value: 'POST', label: 'POST' },
]);

const authTypeOptions = computed(() => [
  { value: 'none', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.NONE') },
  { value: 'bearer', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BEARER') },
  { value: 'basic', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BASIC') },
  {
    value: 'api_key',
    label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.API_KEY'),
  },
]);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() =>
  props.mode === 'edit'
    ? formState.uiFlags.value.updatingItem
    : formState.uiFlags.value.creatingItem
);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.CUSTOM_TOOLS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  endpoint_url: getErrorMessage('endpoint_url', 'ENDPOINT_URL'),
}));

const paramsRef = useTemplateRef('paramsRef');

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

const handleCancel = () => emit('cancel');

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid || !isParamsValid()) {
    return;
  }

  emit('submit', state);
};
</script>

<template>
  <form
    class="flex flex-col px-4 -mx-4 gap-4 max-h-[calc(100vh-200px)] overflow-y-scroll"
    @submit.prevent="handleSubmit"
  >
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
      :rows="2"
    />

    <div class="flex gap-2">
      <div class="flex flex-col gap-1 w-28">
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

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.LABEL') }}
      </label>
      <p class="text-xs text-n-slate-11 -mt-1">
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
    </div>

    <TextArea
      v-if="state.http_method === 'POST'"
      v-model="state.request_template"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.LABEL')"
      :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.PLACEHOLDER')"
      :rows="4"
      class="[&_textarea]:font-mono"
    />

    <TextArea
      v-model="state.response_template"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.LABEL')"
      :placeholder="
        t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.PLACEHOLDER')
      "
      :rows="4"
      class="[&_textarea]:font-mono"
    />

    <div class="flex gap-3 justify-between items-center w-full">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="
          t(mode === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE')
        "
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
