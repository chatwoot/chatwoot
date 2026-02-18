<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ActionBuilder from './ActionBuilder.vue';
import FieldBuilder from './FieldBuilder.vue';

const props = defineProps({
  flow: { type: Object, default: null },
  onClose: { type: Function, required: true },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const TRIGGER_OPTIONS = [
  { value: 'quote_request', label: 'CRM_FLOWS.TRIGGERS.QUOTE_REQUEST' },
  { value: 'advisor_transfer', label: 'CRM_FLOWS.TRIGGERS.ADVISOR_TRANSFER' },
  {
    value: 'appointment_scheduling',
    label: 'CRM_FLOWS.TRIGGERS.APPOINTMENT_SCHEDULING',
  },
  { value: 'lead_creation', label: 'CRM_FLOWS.TRIGGERS.LEAD_CREATION' },
  { value: 'customer_creation', label: 'CRM_FLOWS.TRIGGERS.CUSTOMER_CREATION' },
  {
    value: 'contact_type_changed',
    label: 'CRM_FLOWS.TRIGGERS.CONTACT_TYPE_CHANGED',
  },
  { value: 'ticket_created', label: 'CRM_FLOWS.TRIGGERS.TICKET_CREATED' },
];

const DEFAULT_DEDUP = {
  quote_request: 60,
  advisor_transfer: 30,
  appointment_scheduling: 60,
  lead_creation: 1440,
  customer_creation: 1440,
  contact_type_changed: 60,
  ticket_created: 60,
};

const isEditMode = computed(() => !!props.flow);
const isSubmitting = ref(false);

const formData = ref({
  name: props.flow?.name || '',
  trigger_type: props.flow?.trigger_type || 'quote_request',
  scope_type: props.flow?.scope_type || 'global',
  inbox_id: props.flow?.inbox_id || null,
  actions: props.flow?.actions
    ? JSON.parse(JSON.stringify(props.flow.actions))
    : [],
  required_fields: props.flow?.required_fields
    ? JSON.parse(JSON.stringify(props.flow.required_fields))
    : [],
  active: props.flow?.active !== false,
  dedup_window_minutes:
    props.flow?.dedup_window_minutes ?? DEFAULT_DEDUP.quote_request,
});

const inboxes = computed(() => getters['inboxes/getInboxes'].value || []);

watch(
  () => formData.value.trigger_type,
  newTrigger => {
    if (!isEditMode.value) {
      formData.value.dedup_window_minutes = DEFAULT_DEDUP[newTrigger] || 60;
    }
  }
);

watch(
  () => formData.value.scope_type,
  val => {
    if (val === 'global') formData.value.inbox_id = null;
  }
);

async function handleSubmit() {
  if (!formData.value.name.trim()) {
    useAlert(t('CRM_FLOWS.MODAL.NAME_REQUIRED'));
    return;
  }
  if (!formData.value.actions.length) {
    useAlert(t('CRM_FLOWS.MODAL.ACTIONS_REQUIRED'));
    return;
  }

  isSubmitting.value = true;
  try {
    if (isEditMode.value) {
      await store.dispatch('crmFlows/update', {
        id: props.flow.id,
        ...formData.value,
      });
      useAlert(t('CRM_FLOWS.EDIT.SUCCESS'));
    } else {
      await store.dispatch('crmFlows/create', formData.value);
      useAlert(t('CRM_FLOWS.CREATE.SUCCESS'));
    }
    props.onClose();
  } catch {
    useAlert(
      isEditMode.value ? t('CRM_FLOWS.EDIT.ERROR') : t('CRM_FLOWS.CREATE.ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="
        isEditMode ? $t('CRM_FLOWS.MODAL.SAVE') : $t('CRM_FLOWS.CREATE.BUTTON')
      "
    />

    <form class="w-full" @submit.prevent="handleSubmit">
      <div class="w-full flex flex-col gap-4 max-h-[60vh] overflow-y-auto">
        <!-- Nombre -->
        <div class="w-full">
          <label>
            {{ $t('CRM_FLOWS.MODAL.NAME_LABEL') }}
            <input
              v-model="formData.name"
              type="text"
              :placeholder="$t('CRM_FLOWS.MODAL.NAME_PLACEHOLDER')"
            />
          </label>
        </div>

        <!-- Trigger -->
        <div class="w-full">
          <label>
            {{ $t('CRM_FLOWS.MODAL.TRIGGER_LABEL') }}
            <select v-model="formData.trigger_type">
              <option
                v-for="opt in TRIGGER_OPTIONS"
                :key="opt.value"
                :value="opt.value"
              >
                {{ $t(opt.label) }}
              </option>
            </select>
          </label>
        </div>

        <!-- Scope -->
        <div class="w-full">
          <label>{{ $t('CRM_FLOWS.MODAL.SCOPE_LABEL') }}</label>
          <div class="flex flex-col gap-1.5 mt-1">
            <label
              class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer"
            >
              <input
                v-model="formData.scope_type"
                type="radio"
                value="global"
                class="w-4 h-4"
              />
              {{ $t('CRM_FLOWS.MODAL.SCOPE_GLOBAL') }}
            </label>
            <label
              class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer"
            >
              <input
                v-model="formData.scope_type"
                type="radio"
                value="inbox"
                class="w-4 h-4"
              />
              {{ $t('CRM_FLOWS.MODAL.SCOPE_INBOX') }}
            </label>
          </div>
        </div>

        <!-- Inbox selector (si scope=inbox) -->
        <div v-if="formData.scope_type === 'inbox'" class="w-full">
          <label>
            {{ $t('CRM_FLOWS.MODAL.INBOX_LABEL') }}
            <select v-model="formData.inbox_id">
              <option :value="null">
                {{ $t('CRM_FLOWS.MODAL.INBOX_LABEL') }}
              </option>
              <option
                v-for="inbox in inboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </label>
        </div>

        <hr class="border-n-weak" />

        <!-- ActionBuilder -->
        <ActionBuilder v-model="formData.actions" />

        <hr class="border-n-weak" />

        <!-- FieldBuilder -->
        <FieldBuilder
          v-model="formData.required_fields"
          :actions="formData.actions"
        />

        <hr class="border-n-weak" />

        <!-- Configuración avanzada (collapsible) -->
        <details>
          <summary
            class="text-sm font-medium text-n-slate-11 cursor-pointer select-none"
          >
            {{ $t('CRM_FLOWS.MODAL.ADVANCED') }}
          </summary>
          <div class="mt-2 w-full">
            <label>
              {{ $t('CRM_FLOWS.MODAL.DEDUP_WINDOW_LABEL') }}
              <input
                v-model.number="formData.dedup_window_minutes"
                type="number"
                min="0"
                class="w-24"
              />
            </label>
            <span class="text-xs text-n-slate-9">{{
              $t('CRM_FLOWS.MODAL.DEDUP_WINDOW_HELP')
            }}</span>
          </div>
        </details>
      </div>

      <!-- Footer -->
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <Button
          faded
          slate
          type="reset"
          :label="$t('CRM_FLOWS.MODAL.CANCEL')"
          @click.prevent="onClose"
        />
        <Button
          type="submit"
          :label="$t('CRM_FLOWS.MODAL.SAVE')"
          :disabled="isSubmitting"
          :is-loading="isSubmitting"
        />
      </div>
    </form>
  </div>
</template>
