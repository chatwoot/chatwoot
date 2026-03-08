<script setup>
import { reactive, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const isSubmitting = ref(false);

const CATEGORY_OPTIONS = [
  {
    value: 'MARKETING',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.CATEGORY.OPTIONS.MARKETING'),
  },
  {
    value: 'UTILITY',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.CATEGORY.OPTIONS.UTILITY'),
  },
  {
    value: 'AUTHENTICATION',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.CATEGORY.OPTIONS.AUTHENTICATION'),
  },
];

const LANGUAGE_OPTIONS = [
  { value: 'en', label: 'English' },
  { value: 'en_US', label: 'English (US)' },
  { value: 'en_GB', label: 'English (UK)' },
  { value: 'es', label: 'Spanish' },
  { value: 'pt_BR', label: 'Portuguese (BR)' },
  { value: 'fr', label: 'French' },
  { value: 'de', label: 'German' },
  { value: 'it', label: 'Italian' },
  { value: 'hi', label: 'Hindi' },
  { value: 'ar', label: 'Arabic' },
  { value: 'zh_CN', label: 'Chinese (Simplified)' },
  { value: 'ja', label: 'Japanese' },
  { value: 'ko', label: 'Korean' },
  { value: 'ru', label: 'Russian' },
  { value: 'tr', label: 'Turkish' },
  { value: 'nl', label: 'Dutch' },
  { value: 'pl', label: 'Polish' },
  { value: 'sw', label: 'Swahili' },
  { value: 'id', label: 'Indonesian' },
  { value: 'ms', label: 'Malay' },
];

const HEADER_TYPE_OPTIONS = [
  {
    value: 'NONE',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TYPES.NONE'),
  },
  {
    value: 'TEXT',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TYPES.TEXT'),
  },
  {
    value: 'IMAGE',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TYPES.IMAGE'),
  },
  {
    value: 'VIDEO',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TYPES.VIDEO'),
  },
  {
    value: 'DOCUMENT',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TYPES.DOCUMENT'),
  },
];

const BUTTON_TYPE_OPTIONS = [
  {
    value: 'QUICK_REPLY',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.TYPES.QUICK_REPLY'),
  },
  {
    value: 'PHONE_NUMBER',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.TYPES.PHONE_NUMBER'),
  },
  {
    value: 'URL',
    label: t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.TYPES.URL'),
  },
];

const state = reactive({
  name: '',
  category: '',
  language: '',
  headerType: 'NONE',
  headerText: '',
  body: '',
  footer: '',
  buttons: [],
});

const rules = {
  name: { required },
  category: { required },
  language: { required },
  body: { required },
};

const v$ = useVuelidate(rules, state);

const bodyVariables = computed(() => {
  const matches = state.body.match(/\{\{(\d+)\}\}/g) || [];
  return [...new Set(matches)].map(m => m.replace(/\{\{|\}\}/g, ''));
});

const bodyPreview = computed(() => {
  if (!state.body) return '';
  return state.body;
});

const getErrorMessage = field => {
  const keyMap = {
    name: 'NAME',
    category: 'CATEGORY',
    language: 'LANGUAGE',
    body: 'BODY',
  };
  return v$.value[field]?.$error
    ? t(`WHATSAPP_TEMPLATES.CREATOR.FORM.${keyMap[field]}.ERROR`)
    : '';
};

const addButton = () => {
  if (state.buttons.length >= 3) return;
  state.buttons.push({
    type: 'QUICK_REPLY',
    text: '',
    phone_number: '',
    url: '',
  });
};

const removeButton = index => {
  state.buttons.splice(index, 1);
};

const buildComponents = () => {
  const components = [];

  if (state.headerType !== 'NONE') {
    const header = { type: 'HEADER', format: state.headerType };
    if (state.headerType === 'TEXT' && state.headerText) {
      header.text = state.headerText;
    }
    if (['IMAGE', 'VIDEO', 'DOCUMENT'].includes(state.headerType)) {
      header.example = { header_handle: [] };
    }
    components.push(header);
  }

  const bodyComponent = { type: 'BODY', text: state.body };
  if (bodyVariables.value.length > 0) {
    bodyComponent.example = {
      body_text: [bodyVariables.value.map(v => `sample_${v}`)],
    };
  }
  components.push(bodyComponent);

  if (state.footer) {
    components.push({ type: 'FOOTER', text: state.footer });
  }

  if (state.buttons.length > 0) {
    const buttons = state.buttons
      .filter(b => b.text)
      .map(b => {
        const btn = { type: b.type, text: b.text };
        if (b.type === 'PHONE_NUMBER' && b.phone_number) {
          btn.phone_number = b.phone_number;
        }
        if (b.type === 'URL' && b.url) {
          btn.url = b.url;
          if (b.url.includes('{{')) {
            btn.example = [b.url.replace(/\{\{[^}]+\}\}/, 'example')];
          }
        }
        return btn;
      });
    if (buttons.length > 0) {
      components.push({ type: 'BUTTONS', buttons });
    }
  }

  return components;
};

const handleSubmit = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  isSubmitting.value = true;
  const templateData = {
    name: state.name,
    category: state.category,
    language: state.language,
    components: buildComponents(),
  };
  emit('submit', templateData);
  isSubmitting.value = false;
};

const handleCancel = () => emit('cancel');

const resetForm = () => {
  state.name = '';
  state.category = '';
  state.language = '';
  state.headerType = 'NONE';
  state.headerText = '';
  state.body = '';
  state.footer = '';
  state.buttons = [];
  v$.value.$reset();
};

defineExpose({ isSubmitting, resetForm });
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.name"
      :label="t('WHATSAPP_TEMPLATES.CREATOR.FORM.NAME.LABEL')"
      :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.FORM.NAME.PLACEHOLDER')"
      :message="getErrorMessage('name')"
      :message-type="getErrorMessage('name') ? 'error' : 'info'"
    />
    <p
      v-if="!getErrorMessage('name')"
      class="-mt-3 mb-0 text-xs text-n-slate-10"
    >
      {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.NAME.HELP') }}
    </p>

    <div class="flex gap-3">
      <div class="flex flex-col flex-1 gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.CATEGORY.LABEL') }}
        </label>
        <ComboBox
          v-model="state.category"
          :options="CATEGORY_OPTIONS"
          :has-error="!!getErrorMessage('category')"
          :placeholder="
            t('WHATSAPP_TEMPLATES.CREATOR.FORM.CATEGORY.PLACEHOLDER')
          "
          :message="getErrorMessage('category')"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>

      <div class="flex flex-col flex-1 gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.LANGUAGE.LABEL') }}
        </label>
        <ComboBox
          v-model="state.language"
          :options="LANGUAGE_OPTIONS"
          :has-error="!!getErrorMessage('language')"
          :placeholder="
            t('WHATSAPP_TEMPLATES.CREATOR.FORM.LANGUAGE.PLACEHOLDER')
          "
          :message="getErrorMessage('language')"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>
    </div>

    <!-- Header -->
    <div class="flex flex-col gap-2">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.LABEL') }}
      </label>
      <ComboBox
        v-model="state.headerType"
        :options="HEADER_TYPE_OPTIONS"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
      <Input
        v-if="state.headerType === 'TEXT'"
        v-model="state.headerText"
        :placeholder="
          t('WHATSAPP_TEMPLATES.CREATOR.FORM.HEADER.TEXT_PLACEHOLDER')
        "
      />
    </div>

    <!-- Body -->
    <div class="flex flex-col gap-1">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.BODY.LABEL') }}
      </label>
      <textarea
        v-model="state.body"
        :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.FORM.BODY.PLACEHOLDER')"
        rows="4"
        class="block w-full text-sm rounded-lg resize-y bg-n-alpha-black2 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand border-none placeholder:text-n-slate-10 text-n-slate-12 p-3 transition-all duration-500 ease-in-out"
        :class="{ '!outline-n-ruby-8': getErrorMessage('body') }"
      />
      <p v-if="getErrorMessage('body')" class="mb-0 text-xs text-n-ruby-9">
        {{ getErrorMessage('body') }}
      </p>
      <p v-else class="mb-0 text-xs text-n-slate-10">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.BODY.HELP') }}
      </p>
    </div>

    <!-- Body Preview -->
    <div
      v-if="bodyPreview"
      class="p-3 rounded-lg bg-n-alpha-black2 border border-n-weak"
    >
      <p class="mb-1 text-xs font-medium text-n-slate-10">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.BODY.PREVIEW') }}
      </p>
      <p class="mb-0 text-sm whitespace-pre-wrap text-n-slate-12">
        {{ bodyPreview }}
      </p>
    </div>

    <!-- Footer -->
    <Input
      v-model="state.footer"
      :label="t('WHATSAPP_TEMPLATES.CREATOR.FORM.FOOTER.LABEL')"
      :placeholder="t('WHATSAPP_TEMPLATES.CREATOR.FORM.FOOTER.PLACEHOLDER')"
    />

    <!-- Buttons -->
    <div class="flex flex-col gap-2">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.LABEL') }}
      </label>

      <div
        v-for="(button, index) in state.buttons"
        :key="index"
        class="flex flex-col gap-2 p-3 rounded-lg bg-n-alpha-black2 border border-n-weak"
      >
        <div class="flex gap-2 items-center">
          <ComboBox
            v-model="state.buttons[index].type"
            :options="BUTTON_TYPE_OPTIONS"
            class="flex-1 [&>div>button]:bg-n-solid-2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
          />
          <Button
            variant="faded"
            color="ruby"
            size="sm"
            :label="t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.REMOVE_BUTTON')"
            type="button"
            @click="removeButton(index)"
          />
        </div>
        <Input
          v-model="state.buttons[index].text"
          :placeholder="
            t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.TEXT_PLACEHOLDER')
          "
        />
        <Input
          v-if="button.type === 'PHONE_NUMBER'"
          v-model="state.buttons[index].phone_number"
          :placeholder="
            t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.PHONE_PLACEHOLDER')
          "
        />
        <Input
          v-if="button.type === 'URL'"
          v-model="state.buttons[index].url"
          :placeholder="
            t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.URL_PLACEHOLDER')
          "
        />
      </div>

      <Button
        v-if="state.buttons.length < 3"
        variant="faded"
        color="slate"
        size="sm"
        :label="t('WHATSAPP_TEMPLATES.CREATOR.FORM.BUTTONS.ADD_BUTTON')"
        type="button"
        class="self-start"
        @click="addButton"
      />
    </div>

    <!-- Actions -->
    <div class="flex gap-3 justify-between items-center w-full pt-2">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('WHATSAPP_TEMPLATES.CREATOR.BUTTONS.CANCEL')"
        class="w-full"
        @click="handleCancel"
      />
      <Button
        :label="
          isSubmitting
            ? t('WHATSAPP_TEMPLATES.CREATOR.BUTTONS.CREATING')
            : t('WHATSAPP_TEMPLATES.CREATOR.BUTTONS.CREATE')
        "
        class="w-full"
        type="submit"
        :is-loading="isSubmitting"
        :disabled="isSubmitting"
      />
    </div>
  </form>
</template>
