<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components/widgets/forms/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();

const isEditMode = computed(() => !!route.params.id);
const policyId = computed(() => route.params.id);

const uiFlags = computed(() => getters['assignmentPolicies/getUIFlags'].value);

const loading = ref(false);
const formData = ref({
  name: '',
  description: '',
  assignment_order: 'round_robin',
  conversation_priority: 'earliest_created',
  fair_distribution_limit: 10,
  fair_distribution_window: 3600,
  enabled: true,
});

const assignmentOrderOptions = [
  {
    value: 'round_robin',
    label: 'Round Robin',
    description: 'Distribute conversations evenly among available agents',
  },
  {
    value: 'balanced',
    label: 'Balanced Assignment (Enterprise)',
    description: 'Assign to agents with the most available capacity',
  },
];

const conversationPriorityOptions = [
  {
    value: 'earliest_created',
    label: 'Earliest Created',
    description: 'Assign conversations based on creation time',
  },
  {
    value: 'longest_waiting',
    label: 'Longest Waiting',
    description: 'Assign conversations that have been waiting the longest',
  },
];

const errors = ref({});

const loadPolicy = async () => {
  try {
    loading.value = true;
    const policy = await store.dispatch(
      'assignmentPolicies/show',
      policyId.value
    );
    formData.value = {
      name: policy.name,
      description: policy.description || '',
      assignment_order: policy.assignment_order || 'round_robin',
      conversation_priority: policy.conversation_priority || 'earliest_created',
      fair_distribution_limit: policy.fair_distribution_limit || 10,
      fair_distribution_window: policy.fair_distribution_window || 3600,
      enabled: policy.enabled !== false,
    };
  } catch (error) {
    useAlert(t('ASSIGNMENT_SETTINGS.POLICIES.LOAD.ERROR'));
    router.push({ name: 'assignment_policies_list' });
  } finally {
    loading.value = false;
  }
};

const validateForm = () => {
  errors.value = {};

  if (!formData.value.name.trim()) {
    errors.value.name = t('ASSIGNMENT_SETTINGS.POLICIES.FORM.NAME_REQUIRED');
  }

  if (!formData.value.assignment_order) {
    errors.value.assignment_order = 'Assignment order is required';
  }

  if (!formData.value.conversation_priority) {
    errors.value.conversation_priority = 'Conversation priority is required';
  }

  if (formData.value.fair_distribution_limit < 1) {
    errors.value.fair_distribution_limit =
      'Fair distribution limit must be at least 1';
  }

  if (formData.value.fair_distribution_window < 60) {
    errors.value.fair_distribution_window =
      'Fair distribution window must be at least 60 seconds';
  }

  return Object.keys(errors.value).length === 0;
};

const savePolicy = async () => {
  if (!validateForm()) return;

  try {
    const payload = {
      name: formData.value.name.trim(),
      description: formData.value.description.trim(),
      assignment_order: formData.value.assignment_order,
      conversation_priority: formData.value.conversation_priority,
      fair_distribution_limit: formData.value.fair_distribution_limit,
      fair_distribution_window: formData.value.fair_distribution_window,
      enabled: formData.value.enabled,
    };

    if (isEditMode.value) {
      await store.dispatch('assignmentPolicies/update', {
        id: policyId.value,
        ...payload,
      });
      useAlert(t('ASSIGNMENT_SETTINGS.POLICIES.UPDATE.SUCCESS'));
    } else {
      await store.dispatch('assignmentPolicies/create', payload);
      useAlert(t('ASSIGNMENT_SETTINGS.POLICIES.CREATE.SUCCESS'));
    }

    router.push({ name: 'assignment_policies_list' });
  } catch (error) {
    const message = isEditMode.value
      ? t('ASSIGNMENT_SETTINGS.POLICIES.UPDATE.ERROR')
      : t('ASSIGNMENT_SETTINGS.POLICIES.CREATE.ERROR');
    useAlert(message);
  }
};

const cancel = () => {
  router.push({ name: 'assignment_policies_list' });
};

onMounted(async () => {
  if (isEditMode.value) {
    await loadPolicy();
  }
});
</script>

<template>
  <div>
    <BaseSettingsHeader
      :title="
        isEditMode
          ? $t('ASSIGNMENT_SETTINGS.POLICIES.EDIT_HEADER')
          : $t('ASSIGNMENT_SETTINGS.POLICIES.NEW_HEADER')
      "
      :description="$t('ASSIGNMENT_SETTINGS.POLICIES.FORM_DESCRIPTION')"
      :back-button-label="$t('ASSIGNMENT_SETTINGS.POLICIES.BACK_BUTTON')"
      @back="cancel"
    />

    <div v-if="loading" class="flex items-center justify-center h-64">
      <Spinner :size="48" />
    </div>

    <div v-else class="max-w-2xl p-8">
      <form @submit.prevent="savePolicy">
        <div class="space-y-6">
          <!-- Basic Information -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Basic Information</h3>
            <div class="space-y-4">
              <Input
                v-model="formData.name"
                :label="$t('ASSIGNMENT_SETTINGS.POLICIES.FORM.NAME')"
                :placeholder="
                  $t('ASSIGNMENT_SETTINGS.POLICIES.FORM.NAME_PLACEHOLDER')
                "
                :error="errors.name"
                required
              />

              <TextArea
                v-model="formData.description"
                :label="$t('ASSIGNMENT_SETTINGS.POLICIES.FORM.DESCRIPTION')"
                :placeholder="
                  $t(
                    'ASSIGNMENT_SETTINGS.POLICIES.FORM.DESCRIPTION_PLACEHOLDER'
                  )
                "
                rows="3"
              />

              <div class="flex items-center gap-3">
                <Switch v-model="formData.enabled" />
                <label class="text-sm font-medium"> Policy Enabled </label>
              </div>
            </div>
          </div>

          <!-- Assignment Order -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Assignment Order</h3>
            <div class="space-y-3">
              <div
                v-for="option in assignmentOrderOptions"
                :key="option.value"
                class="p-4 border rounded-lg cursor-pointer transition-colors"
                :class="[
                  formData.assignment_order === option.value
                    ? 'border-woot-500 bg-woot-50'
                    : 'border-slate-200 hover:border-slate-300',
                ]"
                @click="formData.assignment_order = option.value"
              >
                <div class="flex items-start gap-3">
                  <input
                    type="radio"
                    :checked="formData.assignment_order === option.value"
                    class="mt-1"
                  />
                  <div>
                    <h4 class="font-medium">{{ option.label }}</h4>
                    <p class="text-sm text-slate-600 mt-1">
                      {{ option.description }}
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div
              v-if="errors.assignment_order"
              class="text-red-500 text-sm mt-2"
            >
              {{ errors.assignment_order }}
            </div>
          </div>

          <!-- Conversation Priority -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Conversation Priority</h3>
            <div class="space-y-3">
              <div
                v-for="option in conversationPriorityOptions"
                :key="option.value"
                class="p-4 border rounded-lg cursor-pointer transition-colors"
                :class="[
                  formData.conversation_priority === option.value
                    ? 'border-woot-500 bg-woot-50'
                    : 'border-slate-200 hover:border-slate-300',
                ]"
                @click="formData.conversation_priority = option.value"
              >
                <div class="flex items-start gap-3">
                  <input
                    type="radio"
                    :checked="formData.conversation_priority === option.value"
                    class="mt-1"
                  />
                  <div>
                    <h4 class="font-medium">{{ option.label }}</h4>
                    <p class="text-sm text-slate-600 mt-1">
                      {{ option.description }}
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div
              v-if="errors.conversation_priority"
              class="text-red-500 text-sm mt-2"
            >
              {{ errors.conversation_priority }}
            </div>
          </div>

          <!-- Fair Distribution Settings -->
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">Fair Distribution Settings</h3>
            <div class="space-y-4">
              <Input
                v-model.number="formData.fair_distribution_limit"
                type="number"
                label="Fair Distribution Limit"
                placeholder="10"
                help-text="Maximum conversations to assign to an agent within the time window"
                :error="errors.fair_distribution_limit"
                min="1"
                required
              />

              <Input
                v-model.number="formData.fair_distribution_window"
                type="number"
                label="Fair Distribution Window (seconds)"
                placeholder="3600"
                help-text="Time window in seconds for fair distribution (default: 1 hour = 3600 seconds)"
                :error="errors.fair_distribution_window"
                min="60"
                required
              />
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-3 mt-8">
          <Button variant="ghost" @click="cancel">
            {{ $t('COMMON.CANCEL') }}
          </Button>
          <Button
            type="submit"
            variant="primary"
            :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
          >
            {{ isEditMode ? $t('COMMON.UPDATE') : $t('COMMON.CREATE') }}
          </Button>
        </div>
      </form>
    </div>
  </div>
</template>
