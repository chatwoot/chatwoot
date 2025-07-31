<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
// Use native select element instead
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
// Removed DatePicker - using native HTML date inputs instead

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { currentUserId } = useAccount();

const formData = ref({
  agent_id: currentUserId?.value || null,
  leave_type: '',
  start_date: '',
  end_date: '',
  reason: '',
});

const errors = ref({});
const loading = ref(false);

const leaveTypes = [
  { value: 'vacation', label: 'Vacation' },
  { value: 'sick', label: 'Sick Leave' },
  { value: 'personal', label: 'Personal' },
  { value: 'maternity', label: 'Maternity' },
  { value: 'paternity', label: 'Paternity' },
  { value: 'unpaid', label: 'Unpaid' },
  { value: 'other', label: 'Other' },
];

// Removed half day options - not supported by API

const totalDays = computed(() => {
  if (!formData.value.start_date || !formData.value.end_date) return 0;

  const start = new Date(formData.value.start_date);
  const end = new Date(formData.value.end_date);
  const diffTime = Math.abs(end - start);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;

  return diffDays;
});

const validateForm = () => {
  errors.value = {};

  if (!formData.value.leave_type) {
    errors.value.leave_type = 'Leave type is required';
  }

  if (!formData.value.start_date) {
    errors.value.start_date = 'Start date is required';
  }

  if (!formData.value.end_date) {
    errors.value.end_date = 'End date is required';
  }

  if (formData.value.start_date && formData.value.end_date) {
    const start = new Date(formData.value.start_date);
    const end = new Date(formData.value.end_date);

    if (start > end) {
      errors.value.end_date = 'End date must be after start date';
    }

    // Removed half day validation - not supported by API
  }

  if (!formData.value.reason) {
    errors.value.reason = 'Reason is required';
  }

  return Object.keys(errors.value).length === 0;
};

// Removed handleHalfDayChange - not needed without half day functionality

const submitForm = async () => {
  if (!validateForm()) return;

  loading.value = true;
  try {
    const payload = {
      leave: {
        start_date: formData.value.start_date,
        end_date: formData.value.end_date,
        leave_type: formData.value.leave_type,
        reason: formData.value.reason,
      },
      user_id: formData.value.agent_id,
    };

    await store.dispatch('leaves/create', payload);

    useAlert('Leave request created successfully');
    router.push({ name: 'assignment_leaves_list' });
  } catch (error) {
    useAlert(
      `Failed to create leave request: ${error.message || 'Unknown error'}`
    );
  } finally {
    loading.value = false;
  }
};

const cancel = () => {
  router.push({ name: 'assignment_leaves_list' });
};
</script>

<template>
  <div>
    <BaseSettingsHeader
      title="Request Leave"
      description="Create a new leave request. Your manager will be notified for approval."
      back-button-label="Back to Leaves"
      @back="cancel"
    />

    <div class="max-w-2xl p-8">
      <form @submit.prevent="submitForm">
        <div
          class="bg-white rounded-lg shadow-sm border border-slate-200 p-6 space-y-6"
        >
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Leave Type
              <span class="text-red-500">*</span>
            </label>
            <select
              v-model="formData.leave_type"
              class="w-full rounded-md border-slate-300 text-sm"
              :class="{ 'border-red-500': errors.leave_type }"
              required
            >
              <option value="">Select leave type</option>
              <option
                v-for="type in leaveTypes"
                :key="type.value"
                :value="type.value"
              >
                {{ type.label }}
              </option>
            </select>
            <p v-if="errors.leave_type" class="mt-1 text-sm text-red-600">
              {{ errors.leave_type }}
            </p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <!-- Start Date -->
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">
                Start Date
                <span class="text-red-500">*</span>
              </label>
              <input
                v-model="formData.start_date"
                type="date"
                class="w-full rounded-md border-slate-300 text-sm"
                :class="{ 'border-red-500': errors.start_date }"
                :min="new Date().toISOString().split('T')[0]"
                required
              />
              <p v-if="errors.start_date" class="mt-1 text-sm text-red-600">
                {{ errors.start_date }}
              </p>
            </div>

            <!-- End Date -->
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">
                End Date
                <span class="text-red-500">*</span>
              </label>
              <input
                v-model="formData.end_date"
                type="date"
                class="w-full rounded-md border-slate-300 text-sm"
                :class="{ 'border-red-500': errors.end_date }"
                :min="
                  formData.start_date || new Date().toISOString().split('T')[0]
                "
                required
              />
              <p v-if="errors.end_date" class="mt-1 text-sm text-red-600">
                {{ errors.end_date }}
              </p>
            </div>
          </div>

          <!-- Removed half day functionality - not supported by API -->

          <div>
            <div class="text-sm text-slate-600 mb-2">
              Total Days:
              <span class="font-medium text-slate-900">{{ totalDays }}</span>
            </div>
          </div>

          <TextArea
            v-model="formData.reason"
            label="Reason"
            placeholder="Please provide a reason for your leave request"
            :error="errors.reason"
            rows="4"
            required
          />
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <Button variant="clear" @click="cancel"> Cancel </Button>
          <Button type="submit" variant="primary" :loading="loading">
            Submit Request
          </Button>
        </div>
      </form>
    </div>
  </div>
</template>
