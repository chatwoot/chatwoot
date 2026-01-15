<script setup>
import { ref, computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  sourceInbox: {
    type: Object,
    required: true,
  },
  destinationInbox: {
    type: Object,
    required: true,
  },
  previewData: {
    type: Object,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm', 'close']);

const confirmationText = ref('');
const CONFIRMATION_PHRASE = 'MIGRATE';

const isConfirmationValid = computed(() => {
  return confirmationText.value.toUpperCase() === CONFIRMATION_PHRASE;
});

function onConfirm() {
  if (isConfirmationValid.value) {
    emit('confirm');
  }
}
</script>

<template>
  <Modal show :on-close="() => emit('close')">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.TITLE')"
      />

      <div class="p-6">
        <!-- Warning Banner -->
        <div class="p-4 mb-4 rounded-lg bg-n-ruby-2 border border-n-ruby-6">
          <!-- eslint-disable vue/no-bare-strings-in-template -->
          <p class="text-sm font-medium text-n-ruby-11">
            ⚠️ {{ $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.WARNING') }}
          </p>
          <!-- eslint-enable vue/no-bare-strings-in-template -->
        </div>

        <!-- Migration Summary -->
        <div class="mb-4">
          <h4 class="mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.SUMMARY') }}
          </h4>
          <div class="p-3 rounded-lg bg-n-alpha-1">
            <p class="text-sm text-n-slate-12">
              <strong>
                {{ $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.FROM') }}:
              </strong>
              {{ sourceInbox.name }}
            </p>
            <p class="text-sm text-n-slate-12">
              <strong>
                {{ $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.TO') }}:
              </strong>
              {{ destinationInbox.name }}
            </p>
          </div>
        </div>

        <!-- Data to be Migrated -->
        <div class="mb-4">
          <h4 class="mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.DATA_TO_MIGRATE') }}
          </h4>
          <ul class="pl-4 text-sm list-disc text-n-slate-11">
            <li>
              {{ previewData.counts.conversations }}
              {{ $t('INBOX_MGMT.MIGRATION.CONVERSATIONS').toLowerCase() }}
            </li>
            <li>
              {{ previewData.counts.messages }}
              {{ $t('INBOX_MGMT.MIGRATION.MESSAGES').toLowerCase() }}
            </li>
            <li>
              {{ previewData.counts.attachments }}
              {{ $t('INBOX_MGMT.MIGRATION.ATTACHMENTS').toLowerCase() }}
            </li>
            <li>
              {{ previewData.counts.contact_inboxes }}
              {{ $t('INBOX_MGMT.MIGRATION.CONTACTS').toLowerCase() }}
            </li>
            <li
              v-if="previewData.conflicts.overlapping_contacts > 0"
              class="text-n-amber-11"
            >
              {{ previewData.conflicts.overlapping_contacts }}
              {{ $t('INBOX_MGMT.MIGRATION.CONTACTS_WILL_MERGE').toLowerCase() }}
            </li>
          </ul>
        </div>

        <!-- Confirmation Input -->
        <div class="mb-4">
          <label class="mb-1 text-sm font-medium text-n-slate-12">
            {{
              $t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.TYPE_CONFIRM', {
                phrase: CONFIRMATION_PHRASE,
              })
            }}
          </label>
          <input
            v-model="confirmationText"
            type="text"
            class="w-full"
            :placeholder="CONFIRMATION_PHRASE"
            @keyup.enter="onConfirm"
          />
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-2">
          <NextButton
            ghost
            :label="$t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.CANCEL')"
            @click="emit('close')"
          />
          <NextButton
            ruby
            :label="$t('INBOX_MGMT.MIGRATION.CONFIRM_MODAL.CONFIRM')"
            :disabled="!isConfirmationValid || isLoading"
            :is-loading="isLoading"
            @click="onConfirm"
          />
        </div>
      </div>
    </div>
  </Modal>
</template>
