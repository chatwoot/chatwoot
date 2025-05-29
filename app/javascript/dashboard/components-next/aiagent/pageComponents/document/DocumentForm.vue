<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('aiagentDocuments/getUIFlags'),
  topics: useMapGetter('aiagentTopics/getRecords'),
};

const initialState = {
  name: '',
  topicId: null,
};

const state = reactive({ ...initialState });

const validationRules = {
  url: { required, url, minLength: minLength(1) },
  topicId: { required },
};

const topicList = computed(() =>
  formState.topics.value.map(topic => ({
    value: topic.id,
    label: topic.name,
  }))
);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`AIAGENT.DOCUMENTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'URL'),
  topicId: getErrorMessage('topicId', 'TOPIC'),
}));

const handleCancel = () => emit('cancel');

const prepareDocumentDetails = () => ({
  external_link: state.url,
  topic_id: state.topicId,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareDocumentDetails());
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.url"
      :label="t('AIAGENT.DOCUMENTS.FORM.URL.LABEL')"
      :placeholder="t('AIAGENT.DOCUMENTS.FORM.URL.PLACEHOLDER')"
      :message="formErrors.url"
      :message-type="formErrors.url ? 'error' : 'info'"
    />
    <div class="flex flex-col gap-1">
      <label for="topic" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('AIAGENT.DOCUMENTS.FORM.TOPIC.LABEL') }}
      </label>
      <ComboBox
        id="topic"
        v-model="state.topicId"
        :options="topicList"
        :has-error="!!formErrors.topicId"
        :placeholder="t('AIAGENT.DOCUMENTS.FORM.TOPIC.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.topicId"
      />
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('AIAGENT.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('AIAGENT.FORM.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
