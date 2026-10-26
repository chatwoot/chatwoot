<script setup>
defineProps({
  // Customers could set the attribute before it was business managed, so its current values need a check
  warnExistingValues: {
    type: Boolean,
    default: false,
  },
});

const businessManaged = defineModel({ type: Boolean, default: false });
</script>

<template>
  <div class="flex flex-col gap-1 mb-4">
    <label class="flex items-center gap-2 mb-0">
      <input v-model="businessManaged" type="checkbox" class="!m-0" />
      {{ $t('ATTRIBUTES_MGMT.ADD.FORM.BUSINESS_MANAGED.LABEL') }}
    </label>
    <p class="mb-0 text-sm text-n-slate-11">
      {{ $t('ATTRIBUTES_MGMT.ADD.FORM.BUSINESS_MANAGED.HELP') }}
    </p>
    <p
      v-if="warnExistingValues && businessManaged"
      class="mb-0 text-sm text-n-amber-11"
    >
      {{ $t('ATTRIBUTES_MGMT.ADD.FORM.BUSINESS_MANAGED.EXISTING_VALUES') }}
    </p>
  </div>
</template>
