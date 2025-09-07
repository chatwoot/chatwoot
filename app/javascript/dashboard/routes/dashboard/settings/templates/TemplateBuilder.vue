<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import HeaderSection from './components/HeaderSection.vue';
import BodySection from './components/BodySection.vue';
import FooterSection from './components/FooterSection.vue';
import ButtonsSection from './components/ButtonsSection.vue';
import { MEDIA_FORMATS } from 'dashboard/constants/templates';

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

const parameterType = ref('positional'); // 'positional' or 'named'
const isParameterTypeDropdownOpen = ref(false);

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
    media: {},
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
    type: 'FOOTER',
    enabled: false,
    text: '',
  },
  buttons: [],
});

const isValidTemplate = computed(() => {
  const { header, body, footer } = templateData.value;
  if (body.error || !body.text) return false;

  if (header.enabled) {
    const invalidHeaderText = header.format === 'TEXT' && !header.text?.length;
    const invalidHeaderMedia =
      MEDIA_FORMATS.includes(header.format) && !header.media?.blobId;

    if (header.error || invalidHeaderText || invalidHeaderMedia) {
      return false;
    }
  }
  if (footer.enabled && !footer.text) return false;
  return true;
});

const generateComponents = () => {
  const components = [];
  const { header, body, footer, buttons } = templateData.value;

  if (header.enabled) {
    const data = {};
    if (header.format === 'TEXT') {
      data = {
        format: header.format,
        text: header.text,
        example:
          parameterType.value === 'positional'
            ? {
                header_text: header.example.header_text,
              }
            : {
                header_text_named_params:
                  header.example.header_text_named_params,
              },
      };
    } else if (MEDIA_FORMATS.includes(header.format)) {
      data = {
        format: header.format,
        media: header.media, // send media as is -- backend will create a upload handle then create template on meta
      };
    } else {
      // LOCATION
      data = {
        format: header.format,
      };
    }
    components.push({
      type: header.type,
      ...data,
    });
  }
  components.push({
    type: body.type,
    text: body.text,
    example:
      parameterType.value === 'positional'
        ? {
            body_text: body.example.body_text,
          }
        : {
            body_text_named_params: body.example.body_text_named_params,
          },
  });

  if (footer.enabled) {
    components.push({
      type: footer.type,
      text: footer.text,
    });
  }
  components.push(...buttons);

  return components;
};

defineExpose({
  generateComponents,
  isValidTemplate,
  parameterType,
});

const parameterTypesOptions = computed(() => [
  {
    action: 'parameterTypeSelect',
    value: 'positional',
    label: t('SETTINGS.TEMPLATES.BUILDER.PARAMETER_TYPES.OPTIONS.POSITIONAL'),
    isSelected: parameterType.value === 'positional',
  },
  {
    action: 'parameterTypeSelect',
    value: 'named',
    label: t('SETTINGS.TEMPLATES.BUILDER.PARAMETER_TYPES.OPTIONS.NAMED'),
    isSelected: parameterType.value === 'named',
  },
]);

const selectedParameterTypeLabel = computed(() => {
  const selected = parameterTypesOptions.value.find(
    option => option.value === parameterType.value
  );
  return selected ? selected.label : '';
});

const handleParameterTypeAction = ({ value }) => {
  parameterType.value = value;
  isParameterTypeDropdownOpen.value = false;
};

const toggleParameterTypeDropdown = () => {
  isParameterTypeDropdownOpen.value = !isParameterTypeDropdownOpen.value;
};

const closeParameterTypeDropdown = () => {
  isParameterTypeDropdownOpen.value = false;
};
</script>

<template>
  <div class="space-y-12">
    <!-- Parameter Type Selector -->
    <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
      <div class="flex items-center gap-3 mb-4">
        <h4 class="font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.PARAMETER_TYPES.TITLE') }}
        </h4>
      </div>

      <div class="space-y-3">
        <!-- Parameter Type Dropdown -->
        <div
          v-on-click-outside="closeParameterTypeDropdown"
          class="relative w-full"
        >
          <button
            type="button"
            class="flex items-center justify-between gap-2 w-full px-3 py-2 border border-n-blue-5 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5 transition-colors hover:bg-n-solid-2"
            @click="toggleParameterTypeDropdown"
          >
            <span class="truncate">{{ selectedParameterTypeLabel }}</span>
            <Icon
              icon="i-lucide-chevron-down"
              class="size-4 flex-shrink-0 transition-transform"
              :class="{ 'rotate-180': isParameterTypeDropdownOpen }"
            />
          </button>
          <DropdownMenu
            v-if="isParameterTypeDropdownOpen"
            :menu-items="parameterTypesOptions"
            class="absolute top-full mt-1 left-0 right-0 w-full z-50"
            @action="handleParameterTypeAction"
          />
        </div>
      </div>
    </div>

    <HeaderSection
      v-model="templateData.header"
      :parameter-type="parameterType"
    />
    <BodySection v-model="templateData.body" :parameter-type="parameterType" />
    <FooterSection v-model="templateData.footer" />
    <ButtonsSection v-model="templateData.buttons" />
  </div>
</template>
