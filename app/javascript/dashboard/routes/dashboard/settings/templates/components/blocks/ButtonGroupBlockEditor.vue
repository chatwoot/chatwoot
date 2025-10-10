<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localProps = ref({
  buttons: props.properties.buttons || [
    {
      title: 'Button 1',
      type: 'url',
      value: '',
    },
  ],
});

const buttonTypes = [
  { value: 'url', label: 'URL' },
  { value: 'phone', label: 'Phone Number' },
  { value: 'postback', label: 'Postback' },
];

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

const addButton = () => {
  localProps.value.buttons.push({
    title: `Button ${localProps.value.buttons.length + 1}`,
    type: 'url',
    value: '',
  });
};

const removeButton = index => {
  localProps.value.buttons.splice(index, 1);
};

const moveButton = (fromIndex, direction) => {
  const toIndex = fromIndex + direction;
  if (toIndex < 0 || toIndex >= localProps.value.buttons.length) return;

  const buttons = [...localProps.value.buttons];
  [buttons[fromIndex], buttons[toIndex]] = [buttons[toIndex], buttons[fromIndex]];
  localProps.value.buttons = buttons;
};
</script>

<template>
  <div class="space-y-4">
    <div class="flex justify-between items-center">
      <div>
        <h4 class="text-sm font-semibold text-n-slate-12">
          {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.TITLE') }}
        </h4>
        <p class="text-xs text-n-slate-10 mt-1">
          {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.DESCRIPTION') }}
        </p>
      </div>
      <Button icon="i-lucide-plus" xs @click="addButton">
        {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.ADD') }}
      </Button>
    </div>

    <!-- Empty State -->
    <div
      v-if="localProps.buttons.length === 0"
      class="text-center py-8 bg-n-slate-2 rounded-lg"
    >
      <p class="text-sm text-n-slate-11 mb-3">
        {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.EMPTY') }}
      </p>
      <Button icon="i-lucide-plus" @click="addButton">
        {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.ADD_FIRST') }}
      </Button>
    </div>

    <!-- Buttons List -->
    <div v-else class="space-y-3">
      <div
        v-for="(button, index) in localProps.buttons"
        :key="index"
        class="border border-n-weak rounded-lg p-3 bg-n-alpha-1"
      >
        <div class="flex items-start gap-3">
          <!-- Order Controls -->
          <div class="flex flex-col gap-1">
            <button
              :disabled="index === 0"
              class="p-1 text-n-slate-11 hover:text-n-slate-12 disabled:opacity-30 disabled:cursor-not-allowed"
              @click="moveButton(index, -1)"
            >
              <i class="i-lucide-chevron-up text-sm" />
            </button>
            <span class="text-xs text-n-slate-10 text-center">{{
              index + 1
            }}</span>
            <button
              :disabled="index === localProps.buttons.length - 1"
              class="p-1 text-n-slate-11 hover:text-n-slate-12 disabled:opacity-30 disabled:cursor-not-allowed"
              @click="moveButton(index, 1)"
            >
              <i class="i-lucide-chevron-down text-sm" />
            </button>
          </div>

          <!-- Button Fields -->
          <div class="flex-1 space-y-2">
            <!-- Title -->
            <div>
              <label class="block text-xs font-medium text-n-slate-11 mb-1">
                {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.BUTTON_TITLE') }}
              </label>
              <input
                v-model="button.title"
                type="text"
                :placeholder="
                  t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.BUTTON_TITLE_PLACEHOLDER')
                "
                class="w-full px-3 py-2 border border-n-weak rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              />
            </div>

            <!-- Type and Value -->
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block text-xs font-medium text-n-slate-11 mb-1">
                  {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.BUTTON_TYPE') }}
                </label>
                <select
                  v-model="button.type"
                  class="w-full px-3 py-2 border border-n-weak rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                >
                  <option
                    v-for="type in buttonTypes"
                    :key="type.value"
                    :value="type.value"
                  >
                    {{ type.label }}
                  </option>
                </select>
              </div>

              <div>
                <label class="block text-xs font-medium text-n-slate-11 mb-1">
                  {{
                    button.type === 'url'
                      ? t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.URL')
                      : button.type === 'phone'
                        ? t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.PHONE')
                        : t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.PAYLOAD')
                  }}
                </label>
                <input
                  v-model="button.value"
                  type="text"
                  :placeholder="
                    button.type === 'url'
                      ? 'https://example.com'
                      : button.type === 'phone'
                        ? '+1234567890'
                        : 'payload_value'
                  "
                  class="w-full px-3 py-2 border border-n-weak rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                />
              </div>
            </div>
          </div>

          <!-- Remove Button -->
          <button
            class="p-2 text-n-ruby-11 hover:text-n-ruby-12 hover:bg-n-ruby-2 rounded transition-colors"
            @click="removeButton(index)"
          >
            <i class="i-lucide-trash-2 text-sm" />
          </button>
        </div>
      </div>
    </div>

    <!-- Limits Info -->
    <div class="bg-n-blue-2 rounded-lg p-3">
      <p class="text-xs text-n-blue-11">
        <i class="i-lucide-info text-sm mr-1" />
        {{ t('TEMPLATES.BUILDER.BUTTON_GROUP_BLOCK.LIMITS') }}
      </p>
    </div>
  </div>
</template>
