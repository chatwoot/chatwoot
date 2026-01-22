<script setup>
import { ref, computed } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const emit = defineEmits(['submit']);

const MAX_CONTENT_LENGTH = 50000;

const dialogRef = ref(null);
const title = ref('');
const content = ref('');
const isSubmitting = ref(false);

const isOverLimit = computed(() => content.value.length > MAX_CONTENT_LENGTH);
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
      <Input
        v-model="title"
        :label="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.TITLE_LABEL')"
        :placeholder="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.TITLE_PLACEHOLDER')"
      />

      <TextArea
        v-model="content"
        :label="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.CONTENT_LABEL')"
        :placeholder="$t('ALOO.KNOWLEDGE.TEXT_BLOCK.CONTENT_PLACEHOLDER')"
        :max-length="MAX_CONTENT_LENGTH"
        show-character-count
        auto-height
        min-height="16rem"
        max-height="24rem"
      />
    </div>
  </Dialog>
</template>
