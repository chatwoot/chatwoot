<script setup>
import { useI18n } from 'vue-i18n';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  disabledMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const handleChange = () => {
  if (!props.isActive && !props.disabled) {
    emit('select', props.id);
  }
};
</script>

<template>
  <div
    class="relative rounded-xl outline outline-1 p-4 transition-all duration-200 bg-n-solid-1 py-4 ltr:pl-4 rtl:pr-4 ltr:pr-6 rtl:pl-6"
    :class="[
      disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
      isActive ? 'outline-n-blue-9' : 'outline-n-weak',
      !disabled && !isActive ? 'hover:outline-n-strong' : '',
    ]"
    @click="handleChange"
  >
    <div class="absolute top-4 right-4">
      <input
        :id="`${id}`"
        :checked="isActive"
        :value="id"
        :name="id"
        :disabled="disabled"
        type="radio"
        class="h-4 w-4 border-n-slate-6 text-n-brand focus:ring-n-brand focus:ring-offset-0"
        @change="handleChange"
      />
    </div>

    <!-- Content -->
    <div class="flex flex-col gap-3 items-start">
      <div class="flex items-center gap-2">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ label }}
        </h3>
        <span
          v-if="disabled"
          class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-n-yellow-3 text-n-yellow-11"
        >
          {{
            t(
              'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.BALANCED.PREMIUM_BADGE'
            )
          }}
        </span>
      </div>
      <p class="text-sm text-n-slate-11">
        {{ disabled && disabledMessage ? disabledMessage : description }}
      </p>
    </div>
  </div>
</template>
