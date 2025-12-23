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
import TemplatePreview from './components/TemplatePreview.vue';
import {
  generateTemplateComponents,
  validateTemplateData,
} from 'dashboard/helper/templateHelper';

const { t } = useI18n();

const DEFAULT_PARAMETER_TYPE = 'positional';

const getDefaultTemplateData = () => ({
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

const parameterType = ref(DEFAULT_PARAMETER_TYPE); // 'positional' or 'named'
const isParameterTypeDropdownOpen = ref(false);

// TODO: For type constants use COMPONENT_TYPES from templateHelper
const templateData = ref(getDefaultTemplateData());

const isValidTemplate = computed(() => {
  return validateTemplateData(templateData.value);
});

const generateComponents = () => {
  return generateTemplateComponents(templateData.value, parameterType.value);
};

const resetBuilderState = () => {
  parameterType.value = DEFAULT_PARAMETER_TYPE;
  templateData.value = getDefaultTemplateData();
};

defineExpose({
  generateComponents,
  isValidTemplate,
  parameterType,
  resetBuilderState,
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
  <div
    class="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] xl:items-start"
  >
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
      <BodySection
        v-model="templateData.body"
        :parameter-type="parameterType"
      />
      <FooterSection v-model="templateData.footer" />
      <ButtonsSection v-model="templateData.buttons" />
    </div>

    <div class="xl:sticky xl:top-24">
      <TemplatePreview
        :template-data="templateData"
        :parameter-type="parameterType"
      />
    </div>
  </div>
</template>
