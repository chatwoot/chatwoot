<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { vOnClickOutside } from '@vueuse/components';

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

const buttonTypes = computed(() => [
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.VISIT_WEBSITE'),
    icon: 'i-lucide-external-link',
    type: 'URL',
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.CALL_PHONE'),
    icon: 'i-lucide-phone',
    type: 'PHONE_NUMBER',
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.QUICK_REPLY'),
    icon: 'i-lucide-message-circle',
    type: 'QUICK_REPLY',
  },
  {
    label: t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.DROPDOWN.COPY_CODE'),
    icon: 'i-lucide-copy',
    type: 'COPY_CODE',
  },
]);

const addButton = buttonType => {
  const maxButtons = 10; // Meta allows up to 10 buttons
  if (buttonsData.value.length < maxButtons) {
    const defaultButtons = {
      QUICK_REPLY: {
        type: 'QUICK_REPLY',
        text: '',
      },
      URL: {
        type: 'URL',
        text: '',
        url: '',
      },
      PHONE_NUMBER: {
        type: 'PHONE_NUMBER',
        text: '',
        phone_number: '',
      },
      COPY_CODE: {
        type: 'COPY_CODE',
        example: '',
      },
    };

    buttonsData.value = [...buttonsData.value, defaultButtons[buttonType]];
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
        class="bg-n-solid-1 border border-n-weak rounded-lg p-4"
      >
        <div class="grid grid-cols-12 gap-4 items-start">
          <!-- Button Type -->
          <div class="col-span-2">
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.TYPE_LABEL') }}
            </label>
            <div
              class="px-3 py-2 text-sm bg-n-solid-3 rounded text-n-slate-11 h-10 flex items-center"
            >
              {{ buttonTypes.find(b => b.type === button.type).label }}
            </div>
          </div>

          <!-- Button Text -->
          <div class="col-span-3">
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.BUTTON_TEXT') }}
            </label>
            <Input
              v-if="button.type !== 'COPY_CODE'"
              :model-value="button.text"
              :placeholder="
                button.type === 'QUICK_REPLY'
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
          <div v-if="button.type === 'URL'" class="col-span-6">
            <label class="block text-xs font-medium text-n-slate-11 mb-1">
              {{ t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.URL') }}
            </label>
            <Input
              type="url"
              :model-value="button.url"
              :placeholder="
                t('SETTINGS.TEMPLATES.BUILDER.BUTTONS.URL_PLACEHOLDER')
              "
              @update:model-value="updateButton(index, 'url', $event)"
            />
          </div>

          <!-- Phone Number Field -->
          <div v-if="button.type === 'PHONE_NUMBER'" class="col-span-6">
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
          <div v-if="button.type === 'COPY_CODE'" class="col-span-6">
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

          <!-- Delete Button -->
          <div class="col-span-1 flex justify-end">
            <Button
              icon="i-lucide-x"
              variant="ghost"
              color="slate"
              size="sm"
              @click="removeButton(index)"
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
</style>
