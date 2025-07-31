<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  action: {
    type: String,
    required: true,
    validator: value => ['approve', 'reject'].includes(value),
  },
  leave: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['update:show', 'confirm', 'cancel']);

const { t } = useI18n();
const notes = ref('');
const loading = ref(false);

// Reset notes when modal opens/closes
watch(
  () => props.show,
  newValue => {
    if (!newValue) {
      notes.value = '';
      loading.value = false;
    }
  }
);

const title = computed(() => {
  return props.action === 'approve'
    ? t('ASSIGNMENT_SETTINGS.LEAVES.APPROVE.MODAL_TITLE')
    : t('ASSIGNMENT_SETTINGS.LEAVES.REJECT.MODAL_TITLE');
});

const message = computed(() => {
  if (!props.leave) return '';

  const agentName = props.leave.agent?.name || '';
  const dates = `${new Date(props.leave.start_date).toLocaleDateString()} - ${new Date(props.leave.end_date).toLocaleDateString()}`;

  return props.action === 'approve'
    ? t('ASSIGNMENT_SETTINGS.LEAVES.APPROVE.MODAL_MESSAGE', {
        name: agentName,
        dates,
      })
    : t('ASSIGNMENT_SETTINGS.LEAVES.REJECT.MODAL_MESSAGE', {
        name: agentName,
        dates,
      });
});

const confirmText = computed(() => {
  return props.action === 'approve'
    ? t('ASSIGNMENT_SETTINGS.LEAVES.APPROVE.CONFIRM')
    : t('ASSIGNMENT_SETTINGS.LEAVES.REJECT.CONFIRM');
});

const notesLabel = computed(() => {
  return props.action === 'approve'
    ? 'Comments (Optional)'
    : 'Rejection Reason';
});

const notesPlaceholder = computed(() => {
  return props.action === 'approve'
    ? 'Add any comments for this approval...'
    : 'Please provide a reason for rejecting this leave request...';
});

const canConfirm = computed(() => {
  return (
    props.action === 'approve' ||
    (props.action === 'reject' && notes.value.trim())
  );
});

const handleConfirm = async () => {
  if (!canConfirm.value) return;

  loading.value = true;
  try {
    emit('confirm', notes.value.trim());
  } finally {
    loading.value = false;
  }
};

const handleCancel = () => {
  emit('cancel');
  handleClose();
};

const handleClose = () => {
  emit('update:show', false);
  notes.value = '';
  loading.value = false;
};
</script>

<template>
  <Modal :show="show" :on-close="handleClose" size="medium">
    <div class="p-6">
      <div class="flex items-start gap-4">
        <div
          class="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center"
          :class="action === 'approve' ? 'bg-green-100' : 'bg-red-100'"
        >
          <i
            class="text-xl"
            :class="
              action === 'approve'
                ? 'icon-checkmark text-green-600'
                : 'icon-dismiss text-red-600'
            "
          />
        </div>

        <div class="flex-1">
          <h3 class="text-xl font-semibold text-slate-900 mb-2">
            {{ title }}
          </h3>

          <p class="text-slate-600 mb-6">
            {{ message }}
          </p>

          <!-- Leave Details Card -->
          <div
            v-if="leave"
            class="bg-slate-50 rounded-lg p-4 mb-6 border border-slate-200"
          >
            <h4 class="font-medium text-slate-900 mb-3">Leave Details</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
              <div>
                <span class="font-medium text-slate-700">Type:</span>
                <span class="ml-2 capitalize text-slate-900">{{
                  leave.leave_type
                }}</span>
              </div>
              <div>
                <span class="font-medium text-slate-700">Duration:</span>
                <span class="ml-2 text-slate-900">{{ leave.total_days || 'N/A' }} days</span>
              </div>
              <div class="col-span-full">
                <span class="font-medium text-slate-700">Reason:</span>
                <p class="mt-1 text-slate-600 bg-white p-2 rounded border">
                  {{ leave.reason }}
                </p>
              </div>
            </div>
          </div>

          <!-- Notes/Comments -->
          <div class="mb-6">
            <TextArea
              v-model="notes"
              :label="notesLabel"
              :placeholder="notesPlaceholder"
              rows="3"
              :required="action === 'reject'"
            />
            <div
              v-if="action === 'reject' && !notes.trim()"
              class="text-xs text-red-500 mt-1"
            >
              Rejection reason is required
            </div>
          </div>

          <!-- Actions -->
          <div class="flex justify-end gap-3">
            <Button variant="ghost" :disabled="loading" @click="handleCancel">
              {{ t('COMMON.CANCEL') }}
            </Button>
            <Button
              :variant="action === 'approve' ? 'primary' : 'danger'"
              :is-loading="loading"
              :disabled="!canConfirm"
              @click="handleConfirm"
            >
              {{ confirmText }}
            </Button>
          </div>
        </div>
      </div>
    </div>
  </Modal>
</template>
