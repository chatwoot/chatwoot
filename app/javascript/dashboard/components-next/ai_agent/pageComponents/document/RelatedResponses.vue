<script setup>
import { ref, onMounted, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ResponseCard from 'dashboard/components-next/ai_agent/topic/ResponseCard.vue';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  document: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);
const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isLoading = ref(false);
const responses = ref([]);

const documentTitle = computed(() => {
  return props.document?.name || props.document?.external_link || '';
});

const fetchResponses = async () => {
  isLoading.value = true;
  try {
    // In a real implementation, we would fetch related responses from the API
    // For now, just simulate with a delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    responses.value = [
      {
        id: 1,
        question: 'Product Return Policy',
        answer:
          'Our product return policy allows returns within 30 days of purchase...',
        status: 'approved',
        updated_at: Date.now(),
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
      {
        id: 2,
        question: 'Shipping Information',
        answer: 'We offer free shipping on orders over $50...',
        status: 'approved',
        updated_at: Date.now(),
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
    ];
  } catch (error) {
    // Handle error
  } finally {
    isLoading.value = false;
  }
};

const onClose = () => {
  emit('close');
};

onMounted(() => {
  fetchResponses();
});

defineExpose({
  dialogRef,
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    :heading="t('AI_AGENT.DOCUMENTS.RELATED_RESPONSES.TITLE')"
    :subheading="documentTitle"
    :cancel-text="$t('DONE')"
    hide-confirm-button
    @close="onClose"
    @cancel="onClose"
  >
    <div class="min-h-64">
      <div v-if="isLoading" class="flex justify-center items-center h-64">
        <Spinner size="medium" />
      </div>
      <div v-else-if="!responses.length" class="text-center p-4">
        <p class="text-sm text-n-slate-10">
          {{ t('AI_AGENT.DOCUMENTS.RELATED_RESPONSES.EMPTY') }}
        </p>
      </div>
      <div v-else class="space-y-4">
        <ResponseCard
          v-for="response in responses"
          :id="response.id"
          :key="response.id"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :topic="response.topic"
          :updated-at="response.updated_at"
          :created-at="response.created_at"
          compact
        />
      </div>
    </div>
  </Dialog>
</template>
