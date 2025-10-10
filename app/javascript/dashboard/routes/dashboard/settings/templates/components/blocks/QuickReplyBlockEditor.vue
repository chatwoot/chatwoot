<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localProps = ref({
  summaryText: props.properties.summaryText || 'Quick Reply Question',
  items: props.properties.items || [{ title: 'Yes' }, { title: 'No' }],
});

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

const addItem = () => {
  localProps.value.items.push({
    title: '',
  });
};

const removeItem = index => {
  localProps.value.items.splice(index, 1);
};

const moveItem = (fromIndex, direction) => {
  const toIndex = direction === 'up' ? fromIndex - 1 : fromIndex + 1;
  if (toIndex < 0 || toIndex >= localProps.value.items.length) return;

  const items = [...localProps.value.items];
  [items[fromIndex], items[toIndex]] = [items[toIndex], items[fromIndex]];

  localProps.value.items = items;
};
</script>

<template>
  <div class="space-y-4">
    <!-- Summary Text (Question) -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.SUMMARY_TEXT.LABEL') }}
      </label>
      <input
        v-model="localProps.summaryText"
        type="text"
        :placeholder="
          t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.SUMMARY_TEXT.PLACEHOLDER')
        "
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
      />
      <p class="text-xs text-n-slate-10 mt-1">
        {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.SUMMARY_TEXT.DESCRIPTION') }}
      </p>
    </div>

    <!-- Quick Reply Items -->
    <div>
      <div class="flex items-center justify-between mb-3">
        <label class="block text-sm font-medium text-n-slate-12">
          {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.LABEL') }}
        </label>
        <Button size="sm" variant="secondary" @click="addItem">
          {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.ADD') }}
        </Button>
      </div>

      <div class="space-y-3">
        <div
          v-for="(item, index) in localProps.items"
          :key="index"
          class="bg-n-slate-2 rounded-lg p-4 border border-n-slate-6"
        >
          <div class="flex items-start gap-3">
            <!-- Order Buttons -->
            <div class="flex flex-col gap-1 pt-2">
              <button
                type="button"
                :disabled="index === 0"
                class="p-1 rounded hover:bg-n-slate-4 disabled:opacity-30 disabled:cursor-not-allowed"
                @click="moveItem(index, 'up')"
              >
                <svg
                  class="w-4 h-4 text-n-slate-11"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 15l7-7 7 7"
                  />
                </svg>
              </button>
              <button
                type="button"
                :disabled="index === localProps.items.length - 1"
                class="p-1 rounded hover:bg-n-slate-4 disabled:opacity-30 disabled:cursor-not-allowed"
                @click="moveItem(index, 'down')"
              >
                <svg
                  class="w-4 h-4 text-n-slate-11"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
            </div>

            <!-- Item Fields -->
            <div class="flex-1 space-y-3">
              <!-- Title -->
              <div>
                <label class="block text-xs font-medium text-n-slate-11 mb-1">
                  {{
                    t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.TITLE_LABEL')
                  }}
                </label>
                <input
                  v-model="item.title"
                  type="text"
                  :placeholder="
                    t(
                      'TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.TITLE_PLACEHOLDER'
                    )
                  "
                  class="w-full px-3 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 bg-white"
                />
              </div>
            </div>

            <!-- Delete Button -->
            <button
              type="button"
              class="p-2 rounded hover:bg-n-red-3 hover:text-n-red-11 text-n-slate-11 transition-colors"
              @click="removeItem(index)"
            >
              <svg
                class="w-4 h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-if="localProps.items.length === 0"
          class="text-center py-8 text-n-slate-10"
        >
          {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.EMPTY') }}
        </div>
      </div>

      <p class="text-xs text-n-slate-10 mt-2">
        {{ t('TEMPLATES.BUILDER.QUICK_REPLY_BLOCK.ITEMS.DESCRIPTION') }}
      </p>
    </div>
  </div>
</template>
