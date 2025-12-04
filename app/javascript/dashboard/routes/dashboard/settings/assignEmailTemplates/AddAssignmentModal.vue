<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import UserAssignmentsAPI from 'dashboard/api/userAssignments';
import Modal from 'dashboard/components/Modal.vue';
import ModalHeader from 'dashboard/components/ModalHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'create']);

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const loading = ref(false);
const templates = ref([]);
const selectedTemplate = ref(null);
const selectedUser = ref(null);

const agents = computed(() => getters['agents/getAgents'].value);

const fetchTemplates = async () => {
  try {
    const response = await UserAssignmentsAPI.getAvailableTemplates();
    templates.value = response.data;
  } catch (error) {
    useAlert(t('USER_ASSIGNMENTS.FETCH_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('agents/get');
  fetchTemplates();
});

const onClose = () => {
  emit('close');
  selectedTemplate.value = null;
  selectedUser.value = null;
};

const onSubmit = async () => {
  if (!selectedTemplate.value || !selectedUser.value) return;

  loading.value = true;
  try {
    await store.dispatch('userAssignments/create', {
      advanced_email_template_id: selectedTemplate.value,
      user_id: selectedUser.value,
    });
    useAlert(t('USER_ASSIGNMENTS.CREATE_SUCCESS'));
    emit('create');
    onClose();
  } catch (error) {
    useAlert(t('USER_ASSIGNMENTS.CREATE_ERROR'));
  } finally {
    loading.value = false;
  }
};

const templateOptions = computed(() => {
  return templates.value.map(template => ({
    label: template.friendly_name,
    value: template.id,
  }));
});

const agentOptions = computed(() => {
  return agents.value.map(agent => ({
    label: agent.name,
    value: agent.id,
  }));
});
</script>

<template>
  <Modal :show="show" @close="onClose">
    <ModalHeader :header-title="$t('USER_ASSIGNMENTS.ADD_MODAL.TITLE')" />
    <div class="flex flex-col gap-4 p-6">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('USER_ASSIGNMENTS.ADD_MODAL.SELECT_USER') }}
        </label>
        <select
          v-model="selectedUser"
          class="w-full h-10 px-3 py-2 text-sm border rounded-md bg-n-alpha-1 border-n-weak text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
        >
          <option
            v-for="agent in agentOptions"
            :key="agent.value"
            :value="agent.value"
          >
            {{ agent.label }}
          </option>
        </select>
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('USER_ASSIGNMENTS.ADD_MODAL.SELECT_TEMPLATE') }}
        </label>
        <select
          v-model="selectedTemplate"
          class="w-full h-10 px-3 py-2 text-sm border rounded-md bg-n-alpha-1 border-n-weak text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
        >
          <option
            v-for="template in templateOptions"
            :key="template.value"
            :value="template.value"
          >
            {{ template.label }}
          </option>
        </select>
      </div>

      <div class="flex justify-end gap-2 mt-4">
        <Button
          :label="$t('USER_ASSIGNMENTS.ADD_MODAL.CANCEL')"
          variant="ghost"
          @click="onClose"
        />
        <Button
          :label="$t('USER_ASSIGNMENTS.ADD_MODAL.SUBMIT')"
          :is-loading="loading"
          :disabled="!selectedUser || !selectedTemplate"
          @click="onSubmit"
        />
      </div>
    </div>
  </Modal>
</template>
