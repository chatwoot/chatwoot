<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  options: {
    type: Array,
    default: () => [],
    validator: options =>
      options.every(
        opt => typeof opt === 'object' && 'value' in opt && 'label' in opt
      ),
  },
  groups: {
    type: Array,
    default: () => [],
    validator: groups =>
      groups.every(
        group =>
          'label' in group &&
          Array.isArray(group.options) &&
          group.options.every(opt => 'value' in opt && 'label' in opt)
      ),
  },
  placeholder: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
});

const modelValue = defineModel({
  type: [String, Number, Boolean],
  default: '',
});
</script>

<template>
  <div class="w-fit relative">
    <select
      v-model="modelValue"
      :disabled="disabled"
      class="appearance-none bg-none rounded-lg border-0 outline-1 outline -outline-offset-1 transition-all duration-200 bg-s-surface !mb-0 py-2 px-3 pr-10 text-sm"
      :class="{
        'outline-s-border hover:outline-s-border focus:outline-s-brand':
          !error && !disabled,
        'outline-s-error focus:outline-s-error': error && !disabled,
        'outline-s-border bg-s-subtle cursor-not-allowed opacity-60': disabled,
      }"
    >
      <option v-if="placeholder" value="" disabled>
        {{ placeholder }}
      </option>
      <template v-if="groups.length">
        <optgroup
          v-for="group in groups"
          :key="group.label"
          :label="group.label"
        >
          <option
            v-for="option in group.options"
            :key="option.value"
            :value="option.value"
            :disabled="option.disabled"
          >
            {{ option.label }}
          </option>
        </optgroup>
      </template>
      <template v-else>
        <option
          v-for="option in options"
          :key="option.value"
          :value="option.value"
          :disabled="option.disabled"
        >
          {{ option.label }}
        </option>
      </template>
    </select>
    <div
      class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none"
    >
      <Icon
        icon="i-lucide-chevron-down"
        class="size-4 text-s-muted"
        :class="{ 'opacity-50': disabled }"
      />
    </div>
  </div>
</template>
