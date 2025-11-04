<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  currentSeats: {
    type: Number,
    required: true,
  },
  minSeats: {
    type: Number,
    default: 1,
  },
  isUpdatingSeats: {
    type: Boolean,
    default: false,
  },
  updatingDirection: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['updateSeats']);

const { t } = useI18n();

const MAX_SEATS = 999;
const inputSeats = ref(props.currentSeats);
const isEditing = ref(false);
const updatingViaButtons = ref(false);

// Sync input with prop changes
watch(
  () => props.currentSeats,
  newValue => {
    inputSeats.value = newValue;
    isEditing.value = false;
    updatingViaButtons.value = false;
  }
);

const canDecreaseSeats = computed(() => {
  return props.currentSeats > props.minSeats;
});

const canIncreaseSeats = computed(() => {
  return props.currentSeats < MAX_SEATS;
});

const isValidInput = computed(() => {
  const numValue = parseInt(inputSeats.value, 10);
  if (Number.isNaN(numValue)) return false;
  return numValue >= props.minSeats && numValue <= MAX_SEATS;
});

const hasChanges = computed(() => {
  const numValue = parseInt(inputSeats.value, 10);
  if (Number.isNaN(numValue)) return false;
  return numValue !== props.currentSeats;
});

const canUpdate = computed(() => {
  return isEditing.value && hasChanges.value && isValidInput.value;
});

const handleInputFocus = () => {
  isEditing.value = true;
};

const handleInputChange = event => {
  inputSeats.value = event.target.value;
  isEditing.value = true;
};

const handleInputBlur = () => {
  // Don't reset if currently updating
  if (props.isUpdatingSeats) return;

  // Always reset to current seats on blur
  inputSeats.value = props.currentSeats;

  // Hide update button and show +/- buttons
  isEditing.value = false;
};

const handleUpdate = () => {
  if (!isValidInput.value || !hasChanges.value) return;

  const numValue = parseInt(inputSeats.value, 10);
  const direction = numValue > props.currentSeats ? 'increase' : 'decrease';

  emit('updateSeats', {
    quantity: numValue,
    direction,
  });
};

const handleDecreaseSeats = () => {
  if (canDecreaseSeats.value && !props.isUpdatingSeats) {
    // Mark that update is via buttons, not manual input
    isEditing.value = false;
    updatingViaButtons.value = true;
    emit('updateSeats', {
      quantity: props.currentSeats - 1,
      direction: 'decrease',
    });
  }
};

const handleIncreaseSeats = () => {
  if (canIncreaseSeats.value && !props.isUpdatingSeats) {
    // Mark that update is via buttons, not manual input
    isEditing.value = false;
    updatingViaButtons.value = true;
    emit('updateSeats', {
      quantity: props.currentSeats + 1,
      direction: 'increase',
    });
  }
};
</script>

<template>
  <div
    class="flex items-center justify-between p-4 rounded-lg bg-n-slate-2 dark:bg-n-solid-2"
  >
    <div class="flex items-center gap-3">
      <div
        class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-blue-3 dark:bg-n-blue-4"
      >
        <Icon icon="i-lucide-users" class="text-n-blue-11" />
      </div>
      <div>
        <h6 class="text-sm font-semibold text-n-slate-12">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.NUMBER_OF_SEATS') }}
        </h6>
        <p class="text-xs text-n-slate-11">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.ADJUST_SEATS_HINT') }}
        </p>
      </div>
    </div>

    <div class="flex items-center flex-shrink-0 gap-2">
      <Button
        v-if="!isEditing"
        faded
        slate
        sm
        icon="i-lucide-minus"
        type="button"
        :is-loading="
          isUpdatingSeats &&
          updatingViaButtons &&
          updatingDirection === 'decrease'
        "
        :disabled="!canDecreaseSeats || isUpdatingSeats"
        @click="handleDecreaseSeats"
      />

      <Input
        v-model="inputSeats"
        type="number"
        :min="String(minSeats)"
        :max="String(MAX_SEATS)"
        :disabled="isUpdatingSeats"
        class="w-20 text-center text-lg [&>input]:!py-1 [&>input]:!h-8"
        @focus="handleInputFocus"
        @input="handleInputChange"
        @blur="handleInputBlur"
      />

      <Button
        v-if="!isEditing"
        faded
        slate
        sm
        icon="i-lucide-plus"
        type="button"
        :is-loading="
          isUpdatingSeats &&
          updatingViaButtons &&
          updatingDirection === 'increase'
        "
        :disabled="!canIncreaseSeats || isUpdatingSeats"
        @click="handleIncreaseSeats"
      />

      <Button
        v-if="isEditing"
        color="blue"
        size="sm"
        :disabled="!canUpdate || isUpdatingSeats"
        :is-loading="isUpdatingSeats"
        @mousedown.prevent
        @click="handleUpdate"
      >
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.UPDATE') }}
      </Button>
    </div>
  </div>
</template>
