<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  helpText: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="w-full py-2 mb-2 [interpolate-size:allow-keywords]">
    <div
      class="grid grid-cols-1 lg:grid-cols-8 gap-1.5 lg:gap-4 items-start lg:items-center"
    >
      <label class="text-heading-3 text-n-slate-12 col-span-1 lg:col-span-2">
        {{ label }}
      </label>
      <div class="col-span-1 lg:col-span-6">
        <slot />
      </div>
    </div>
    <div v-if="helpText" class="grid grid-cols-1 lg:grid-cols-8">
      <div class="col-span-1 lg:col-span-2 invisible" />
      <p
        v-if="helpText"
        class="mt-1.5 col-span-1 lg:col-span-6 text-label-small text-n-slate-11 ltr:ml-1 rtl:mr-1"
      >
        {{ helpText }}
      </p>
    </div>
    <slot name="extra" />
  </div>
</template>
