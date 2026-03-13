<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['submit']);

const store = useStore();
const getters = useStoreGetters();

const dialogRef = ref(null);
const conversationContext = ref(null);
const classificationId = ref(null);
const closingNote = ref('');

const classifications = computed(
  () => getters['conversationClassifications/getAll'].value
);

const currentAccount = computed(() => getters.getCurrentAccount.value);

const requireClassification = computed(
  () =>
    currentAccount.value?.settings?.require_classification_on_resolve !== false
);

const requireClosingNote = computed(
  () => currentAccount.value?.settings?.require_closing_note_on_resolve === true
);

const classificationOptions = computed(() =>
  classifications.value.map(c => ({ value: c.id, label: c.name }))
);

const isConfirmDisabled = computed(() => {
  if (requireClassification.value && !classificationId.value) return true;
  if (requireClosingNote.value && !closingNote.value.trim()) return true;
  return false;
});

const open = context => {
  conversationContext.value = context;
  // Pre-fill from existing conversation data
  classificationId.value = context.classificationId || null;
  closingNote.value = context.closingNote || '';
  dialogRef.value?.open();
};

const handleConfirm = () => {
  emit('submit', {
    context: conversationContext.value,
    classificationId: classificationId.value,
    closingNote: closingNote.value,
  });
  dialogRef.value?.close();
};

onMounted(() => {
  store.dispatch('conversationClassifications/get');
});

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('RESOLUTION_MODAL.TITLE')"
    :description="$t('RESOLUTION_MODAL.DESCRIPTION')"
    :confirm-button-label="$t('RESOLUTION_MODAL.CONFIRM')"
    :cancel-button-label="$t('RESOLUTION_MODAL.CANCEL')"
    :disable-confirm-button="isConfirmDisabled"
    show-cancel-button
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4 pt-2">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.CLASSIFICATION.LABEL') }}
          <span v-if="requireClassification" class="text-n-ruby-9">{{
            '*'
          }}</span>
        </label>
        <select
          v-model="classificationId"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
        >
          <option :value="null" disabled>
            {{ $t('RESOLUTION_MODAL.CLASSIFICATION.PLACEHOLDER') }}
          </option>
          <option
            v-for="option in classificationOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
        <p
          v-if="requireClassification && !classificationId"
          class="text-xs text-n-slate-10"
        >
          {{ $t('RESOLUTION_MODAL.CLASSIFICATION.REQUIRED_HINT') }}
        </p>
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.CLOSING_NOTE.LABEL') }}
          <span v-if="requireClosingNote" class="text-n-ruby-9">{{ '*' }}</span>
        </label>
        <textarea
          v-model="closingNote"
          :placeholder="$t('RESOLUTION_MODAL.CLOSING_NOTE.PLACEHOLDER')"
          rows="3"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
        />
      </div>
    </div>
  </Dialog>
</template>
