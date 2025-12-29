<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  item: {
    type: Object,
    default: null,
  },
  category: {
    type: Object,
    default: null,
  },
  isDeleting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'confirm']);

const { t } = useI18n();

const isCategory = computed(() => !!props.category);
const title = computed(() =>
  isCategory.value
    ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE')
    : t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE')
);
const description = computed(() =>
  isCategory.value
    ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_CONFIRM')
    : t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE_CONFIRM')
);
const itemName = computed(() =>
  isCategory.value
    ? props.category?.name
    : props.item?.primary_question
);
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    @click.self="emit('close')"
  >
    <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4">
      <!-- Header -->
      <div class="flex items-center gap-3 px-6 py-4 border-b border-n-weak">
        <div class="p-2 rounded-full bg-n-ruby-3">
          <span class="i-lucide-trash-2 size-5 text-n-ruby-11" />
        </div>
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ title }}
        </h2>
      </div>

      <!-- Body -->
      <div class="px-6 py-4">
        <p class="text-sm text-n-slate-11 mb-3">
          {{ description }}
        </p>
        <div class="p-3 bg-n-alpha-2 rounded-lg">
          <p class="text-sm font-medium text-n-slate-12 truncate">
            {{ itemName }}
          </p>
        </div>
        <p
          v-if="isCategory"
          class="mt-3 text-xs text-n-ruby-11"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_WARNING') }}
        </p>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-n-weak">
        <woot-button
          color-scheme="secondary"
          size="small"
          @click="emit('close')"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.CANCEL') }}
        </woot-button>
        <woot-button
          color-scheme="alert"
          size="small"
          :loading="isDeleting"
          @click="emit('confirm')"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.DELETE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
