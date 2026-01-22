<script setup>
import { ref, computed } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['submit']);

const MAX_CONTENT_LENGTH = 50000;

const dialogRef = ref(null);
const title = ref('');
const content = ref('');
const isSubmitting = ref(false);

const characterCount = computed(() => content.value.length);
const isOverLimit = computed(() => characterCount.value > MAX_CONTENT_LENGTH);
const isValid = computed(
  () => title.value.trim() && content.value.trim() && !isOverLimit.value
);

const open = () => {
  title.value = '';
  content.value = '';
  isSubmitting.value = false;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleSubmit = async () => {
  if (!isValid.value || isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    await emit('submit', {
      title: title.value.trim(),
      content: content.value.trim(),
    });
    close();
  } finally {
    isSubmitting.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.TITLE')"
    :confirm-button-label="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.ADD')"
    :disable-confirm-button="!isValid"
    :is-loading="isSubmitting"
    width="xl"
    @confirm="handleSubmit"
  >
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
          {{ $t('ALOO.KNOWLEDGE.TEXT_BLOCK.TITLE_LABEL') }}
        </label>
        <input
          v-model="title"
          type="text"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7 focus:border-transparent"
          :placeholder="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.TITLE_PLACEHOLDER')"
        />
      </div>

      <div>
        <div class="flex items-center justify-between mb-1.5">
          <label class="block text-sm font-medium text-n-slate-12">
            {{ $t('ALOO.KNOWLEDGE.TEXT_BLOCK.CONTENT_LABEL') }}
          </label>
          <span
            class="text-xs"
            :class="isOverLimit ? 'text-n-ruby-11' : 'text-n-slate-10'"
          >
            {{
              $t('ALOO.KNOWLEDGE.TEXT_BLOCK.CHARACTER_COUNT', {
                current: characterCount.toLocaleString(),
                max: MAX_CONTENT_LENGTH.toLocaleString(),
              })
            }}
          </span>
        </div>
        <textarea
          v-model="content"
          rows="12"
          class="w-full px-3 py-2 rounded-lg border bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7 focus:border-transparent resize-none"
          :class="
            isOverLimit
              ? 'border-n-ruby-7 focus:ring-n-ruby-7'
              : 'border-n-weak'
          "
          :placeholder="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.CONTENT_PLACEHOLDER')"
        />
        <p v-if="isOverLimit" class="mt-1 text-xs text-n-ruby-11">
          {{ $t('ALOO.KNOWLEDGE.TEXT_BLOCK.OVER_LIMIT') }}
        </p>
      </div>
    </div>
  </Dialog>
</template>
