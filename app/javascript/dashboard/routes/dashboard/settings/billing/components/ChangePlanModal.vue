<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PlanCard from './PlanCard.vue';

const props = defineProps({
  plans: {
    type: Array,
    default: () => [],
  },
  currentPlanId: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isSubscribeMode: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const selectedPlanId = ref(props.currentPlanId);

const selectedPlan = computed(() => {
  return filteredPlans.value.find(p => p.id === selectedPlanId.value);
});

// Filter out Hacker plan when user already has a subscription (change plan mode)
const filteredPlans = computed(() => {
  if (props.isSubscribeMode) {
    // In subscribe mode (no subscription), show all plans including Hacker
    return props.plans;
  }
  // In change plan mode (has subscription), hide Hacker plan
  return props.plans.filter(
    plan => plan.display_name?.toLowerCase() !== 'hacker'
  );
});

const isCurrentPlanSelected = computed(() => {
  return selectedPlanId.value === props.currentPlanId;
});

const modalTitle = computed(() => {
  if (props.isSubscribeMode) {
    return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.SUBSCRIBE_TITLE');
  }
  return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.TITLE');
});

const modalDescription = computed(() => {
  if (props.isSubscribeMode) {
    return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.SUBSCRIBE_DESCRIPTION');
  }
  return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.DESCRIPTION');
});

const confirmButtonLabel = computed(() => {
  if (isCurrentPlanSelected.value) {
    return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.CURRENT_PLAN');
  }
  if (props.isSubscribeMode) {
    return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.SUBSCRIBE');
  }
  return t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.CHANGE_PLAN');
});

const handlePlanSelect = plan => {
  selectedPlanId.value = plan.id;
};

const handleConfirm = () => {
  if (!isCurrentPlanSelected.value && selectedPlan.value) {
    emit('select', selectedPlan.value);
  }
};

const handleClose = () => {
  emit('close');
};

const open = () => {
  selectedPlanId.value = props.currentPlanId;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="modalTitle"
    :description="modalDescription"
    width="2xl"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <div class="grid grid-cols-3 gap-4">
      <PlanCard
        v-for="plan in filteredPlans"
        :key="plan.id"
        :plan="plan"
        :is-selected="selectedPlanId === plan.id"
        :is-current="plan.id === currentPlanId"
        :is-disabled="isLoading || plan.id === currentPlanId"
        @select="handlePlanSelect"
      />
    </div>
    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.CANCEL')"
          class="w-full"
          :disabled="isLoading"
          @click="close"
        />
        <Button
          color="slate"
          solid
          :label="confirmButtonLabel"
          class="w-full"
          :disabled="isCurrentPlanSelected || isLoading"
          :is-loading="isLoading"
          @click="handleConfirm"
        />
      </div>
    </template>
  </Dialog>
</template>
