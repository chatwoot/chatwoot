<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import VariableSection from './VariableSection.vue';
import { vOnClickOutside } from '@vueuse/components';
import { BUTTON_TYPES } from 'dashboard/helper/templateHelper';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const showDropdown = ref(false);

const buttonsData = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const BUTTON_CATEGORY = {
  [BUTTON_TYPES.URL]: 'cta',
  [BUTTON_TYPES.PHONE_NUMBER]: 'cta',
  [BUTTON_TYPES.COPY_CODE]: 'cta',
  [BUTTON_TYPES.QUICK_REPLY]: 'quickReply',
};

const buttonTypes = computed(() => [
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.VISIT_WEBSITE'),
    icon: 'i-lucide-external-link',
    type: BUTTON_TYPES.URL,
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.CALL_PHONE'),
    icon: 'i-lucide-phone',
    type: BUTTON_TYPES.PHONE_NUMBER,
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.QUICK_REPLY'),
    icon: 'i-lucide-reply',
    type: BUTTON_TYPES.QUICK_REPLY,
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.COPY_CODE'),
    icon: 'i-lucide-copy',
    type: BUTTON_TYPES.COPY_CODE,
  },
]);

const getButtonCategory = type => BUTTON_CATEGORY[type] || 'cta';

const addButton = buttonType => {
  const maxButtons = 10; // Meta allows up to 10 buttons
  if (buttonsData.value.length < maxButtons) {
    const defaultButtons = {
      [BUTTON_TYPES.QUICK_REPLY]: {
        type: BUTTON_TYPES.QUICK_REPLY,
        text: 'Quick Reply',
      },
      [BUTTON_TYPES.URL]: {
        type: BUTTON_TYPES.URL,
        text: 'Visit website',
        url: '',
        example: [],
        error: '',
      },
      [BUTTON_TYPES.PHONE_NUMBER]: {
        type: BUTTON_TYPES.PHONE_NUMBER,
        text: 'Call phone number',
        phone_number: '',
      },
      [BUTTON_TYPES.COPY_CODE]: {
        type: BUTTON_TYPES.COPY_CODE,
        example: '',
      },
    };
    const newButton = defaultButtons[buttonType];
    const newButtons = [...buttonsData.value];
    const category = getButtonCategory(buttonType);
    // find button with the same category from last and add new button after it
    const found = newButtons
      .toReversed()
      .findIndex(btn => getButtonCategory(btn.type) === category);
    const idx = newButtons.length - (found >= 0 ? found : 0);
    newButtons.splice(idx, 0, newButton);
    buttonsData.value = newButtons;
  }
  showDropdown.value = false;
};

const handleDropdownAction = ({ type }) => {
  addButton(type);
};

const removeButton = index => {
  buttonsData.value = buttonsData.value.filter((_, i) => i !== index);
};

const updateButton = (index, field, value) => {
  const newButtons = [...buttonsData.value];
  newButtons[index] = {
    ...newButtons[index],
    [field]: value,
  };
  buttonsData.value = newButtons;
};

const canAddMoreButtons = computed(() => {
  return buttonsData.value.length < 10;
});

const getUrlVariableData = button => ({
  text: button.url,
  examples: button.example,
  error: button.error,
});

const updateUrlWithVariable = (index, variableData) => {
  const newButtons = [...buttonsData.value];
  let error = variableData.error;
  if (
    !error &&
    variableData.examples.length &&
    !variableData.text.endsWith('{{1}}')
  ) {
    error = 'should be at end';
  }
  newButtons[index] = {
    ...newButtons[index],
    url: variableData.text,
    example: variableData.examples,
    error,
  };
  buttonsData.value = newButtons;
};

const getButtonTypeMeta = type =>
  buttonTypes.value.find(button => button.type === type) || {
    label: '',
    icon: null,
  };
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div v-if="buttonsData.length === 0">
      <h3 class="text-base font-medium text-n-slate-12 mb-2">
        {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.BUTTONS_LABEL') }}
      </h3>
      <span class="text-xs text-n-slate-11 bg-n-solid-3 px-2 py-1 rounded">
        {{ t('SETTINGS.TEMPLATES.BUILDER.OPTIONAL') }}
      </span>
      <p class="text-sm text-n-slate-11 mt-2">
        {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DESCRIPTION') }}
      </p>
    </div>

    <!-- Add Button Dropdown -->
    <div
      v-if="canAddMoreButtons"
      v-on-click-outside="() => (showDropdown = false)"
      class="relative"
    >
      <Button
        :label="t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.ADD_BUTTON')"
        icon="i-lucide-plus"
        :trailing-icon="
          showDropdown ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
        "
        color="slate"
        variant="outline"
        size="md"
        :disabled="buttonsData.length >= 10"
        @click="showDropdown = !showDropdown"
      />

      <DropdownMenu
        v-if="showDropdown"
        :menu-items="
          buttonTypes.map(item => ({
            ...item,
            action: 'add',
            value: item.type,
          }))
        "
        class="ltr:left-0 rtl:right-0 z-[100] top-full mt-1 overflow-y-auto max-h-60"
        @action="handleDropdownAction"
      />
    </div>

    <!-- Buttons List -->
    <div v-if="buttonsData.length > 0" class="space-y-4">
      <div class="flex items-center gap-2">
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.BUTTONS_LABEL') }}
        </h4>
        <span class="text-xs text-n-slate-11 bg-n-solid-3 px-2 py-1 rounded">
          {{ t('SETTINGS.TEMPLATES.BUILDER.OPTIONAL') }}
        </span>
      </div>

      <div
        v-for="(button, index) in buttonsData"
        :key="`button-${index}`"
        class="bg-n-solid-1 border border-n-weak rounded-lg p-4 space-y-1"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-center gap-2">
            <Icon
              v-if="getButtonTypeMeta(button.type).icon"
              :icon="getButtonTypeMeta(button.type).icon"
              class="size-5 text-n-slate-11"
            />
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ getButtonTypeMeta(button.type).label }}
              </p>
            </div>
          </div>
          <Button
            icon="i-lucide-x"
            variant="ghost"
            color="slate"
            size="sm"
            @click="removeButton(index)"
          />
        </div>

        <div class="grid gap-4 md:grid-cols-2 items-start">
          <div class="md:col-span-1 w-full">
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.BUTTON_TEXT') }}
            </label>
            <Input
              v-if="button.type !== BUTTON_TYPES.COPY_CODE"
              :model-value="button.text"
              :placeholder="
                button.type === BUTTON_TYPES.QUICK_REPLY
                  ? t(
                      'SETTINGS.TEMPLATES.BUILDER.BUTTONS.PLACEHOLDERS.QUICK_REPLY'
                    )
                  : t(
                      'SETTINGS.TEMPLATES.BUILDER.BUTTONS.PLACEHOLDERS.BUTTON_TEXT'
                    )
              "
              @update:model-value="updateButton(index, 'text', $event)"
            />
            <div
              v-else
              class="px-3 py-2 text-sm bg-n-solid-3 rounded text-n-slate-11 h-10 flex items-center"
            >
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.COPY_CODE') }}
            </div>
          </div>

          <!-- URL Field -->
          <!--url can have max 1 dynamic variable but doesn't support named format-->
          <div
            v-if="button.type === BUTTON_TYPES.URL"
            class="md:col-span-1 w-full url-variable-container"
          >
            <VariableSection
              :model-value="getUrlVariableData(button)"
              input-type="input"
              :max-length="2000"
              :placeholder="
                t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.URL_PLACEHOLDER')
              "
              :label="t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.URL')"
              parameter-type="positional"
              :max-variables="1"
              :show-character-count="false"
              @update:model-value="updateUrlWithVariable(index, $event)"
            />
          </div>

          <!-- Phone Number Field -->
          <div
            v-if="button.type === BUTTON_TYPES.PHONE_NUMBER"
            class="md:col-span-1"
          >
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.PHONE_NUMBER') }}
            </label>
            <div class="phone-input-container">
              <PhoneNumberInput
                v-model="button.phone_number"
                :placeholder="
                  t(
                    'SETTINGS.TEMPLATES.BUILDER.BUTTONS.PLACEHOLDERS.PHONE_NUMBER'
                  )
                "
                @update:model-value="
                  updateButton(index, 'phone_number', $event)
                "
              />
            </div>
          </div>

          <!-- Copy Code Example Field -->
          <div
            v-if="button.type === BUTTON_TYPES.COPY_CODE"
            class="md:col-span-1 w-full"
          >
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.EXAMPLE_CODE_LABEL') }}
            </label>
            <Input
              :model-value="button.example"
              :placeholder="
                t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.EXAMPLE_CODE_PLACEHOLDER')
              "
              @update:model-value="updateButton(index, 'example', $event)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.phone-input-container :deep(div > div:first-child) {
  height: 2.5rem !important;
}

.phone-input-container :deep(input) {
  height: 2.5rem !important;
}

.phone-input-container :deep(button) {
  height: 2.375rem !important;
}

/* URL Variable Section styles */
.url-variable-container :deep(input) {
  @apply h-10 text-sm;
}

.url-variable-container :deep(label) {
  @apply text-xs text-n-slate-11 mb-1;
}
</style>
