<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import HeaderSection from './components/HeaderSection.vue';
import BodySection from './components/BodySection.vue';
import FooterSection from './components/FooterSection.vue';
import ButtonsSection from './components/ButtonsSection.vue';

const emit = defineEmits(['update:template']);
const { t } = useI18n();

/*
Component structure

Header:
{
  "type": "HEADER",
  "format": "TEXT",
  "text": "Our new sale starts {{1}}!",
  "example": {
    "header_text": [
      "December 1st"
    ]
  }
} | {
  "type": "HEADER",
  "format": "TEXT",
  "text": "Our new sale starts {{sale_start_date}}!",
  "example": {
    "header_text_named_params": [
      {
        "param_name": "sale_start_date",
        "example": "December 1st"
      }
    ]
  }
} | {
  "type": "HEADER",
  "format": "<FORMAT>", // `IMAGE`, `VIDEO`, or `DOCUMENT`
  "example": {
    "header_handle": [
      "<HEADER_HANDLE>"
    ]
  }
} | {
  "type": "HEADER",
  "format": "LOCATION"
}
*/

// const variableType = ref('number'); // 'number' or 'named'
const variableType = ref('named'); // 'number' or 'named'

const templateData = ref({
  header: {
    enabled: false,
    type: 'HEADER',
    format: 'TEXT',
    text: '',
    example: {
      header_text: [],
      header_text_named_params: [], // param_name, example object
    },
    error: '',
  },
  body: {
    type: 'BODY',
    text: '',
    example: {
      body_text: [],
      body_text_named_params: [],
    },
    error: '',
  },
  footer: {
    enabled: false,
    text: '',
  },
  buttons: [],
});

const isValidTemplate = computed(() => {
  const hasRequiredText = templateData.value.body.text.trim().length > 0;
  const hasHeaderError = templateData.value.header.error.length > 0;
  const hasBodyError = templateData.value.body.error.length > 0;

  return hasRequiredText && !hasHeaderError && !hasBodyError;
});

const generateComponents = computed(() => {
  const components = [];
  return components;
});

const generateContentString = () => {
  let content = '';

  if (
    templateData.value.header.enabled &&
    templateData.value.header.format === 'TEXT'
  ) {
    content += `${templateData.value.header.text}\n\n`;
  }

  content += templateData.value.body.text;

  if (templateData.value.footer.enabled && templateData.value.footer.text) {
    content += `\n\n${templateData.value.footer.text}`;
  }

  return content;
};

watch(
  templateData,
  () => {
    emit('update:template', {
      components: generateComponents.value,
      content: generateContentString(),
      isValid: isValidTemplate.value,
    });
  },
  { deep: true }
);

const variableTypesOptions = computed(() => [
  {
    name: t('SETTINGS.TEMPLATES.BUILDER.VARIABLE_TYPES.OPTIONS.NUMBER'),
    value: 'number',
  },
  {
    name: t('SETTINGS.TEMPLATES.BUILDER.VARIABLE_TYPES.OPTIONS.NAMED'),
    value: 'named',
  },
]);
</script>

<template>
  <div class="space-y-12">
    <!-- Variable Type Selector -->
    <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
      <div class="flex items-center gap-3 mb-4">
        <h4 class="font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.VARIABLE_TYPES.TITLE') }}
        </h4>
      </div>

      <div class="space-y-3">
        <!-- Dropdown -->
        <select
          v-model="variableType"
          class="w-full px-3 py-2 border border-n-blue-5 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5 pr-8"
        >
          <option
            v-for="option in variableTypesOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.name }}
          </option>
        </select>
      </div>
    </div>

    <HeaderSection
      v-model="templateData.header"
      :variable-type="variableType"
    />
    <BodySection v-model="templateData.body" :variable-type="variableType" />
    <FooterSection v-model="templateData.footer" />
    <ButtonsSection v-model="templateData.buttons" />
  </div>
</template>
