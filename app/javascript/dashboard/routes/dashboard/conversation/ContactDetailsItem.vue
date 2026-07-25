<script>
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';

export default {
  components: { OutlinedAttributeField },
  props: {
    title: { type: String, required: true },
    value: { type: [String, Number], default: '' },
    compact: { type: Boolean, default: false },
    /** Label left / value right (legacy). */
    inline: { type: Boolean, default: false },
    /** Floating-label outlined shell (System metadata rows). */
    outlined: { type: Boolean, default: false },
  },
  computed: {
    hasValue() {
      return (
        this.value !== null && this.value !== undefined && this.value !== ''
      );
    },
  },
};
</script>

<template>
  <!-- Outlined floating label (conversation System attrs) -->
  <div v-if="outlined" class="px-1 py-1">
    <OutlinedAttributeField :label="title" :filled="hasValue">
      <div
        class="flex items-center min-h-8 text-sm text-n-slate-12 break-words"
      >
        <slot>
          <span :class="{ 'opacity-0': !hasValue }">{{
            value || '\u00A0'
          }}</span>
        </slot>
      </div>
    </OutlinedAttributeField>
  </div>

  <!-- Legacy layouts (ConversationAction, etc.) -->
  <div
    v-else
    class="overflow-auto"
    :class="[
      compact || inline ? 'py-1.5 px-2' : 'py-3 px-4',
      inline ? 'flex items-start gap-2' : '',
    ]"
  >
    <div
      :class="
        inline ? 'w-[34%] shrink-0' : 'items-center flex justify-between mb-1.5'
      "
    >
      <span
        class="font-medium text-n-slate-11"
        :class="
          inline ? 'text-xs leading-8 truncate' : 'text-sm text-n-slate-12'
        "
        :title="title"
      >
        {{ title }}
      </span>
      <slot v-if="!inline" name="button" />
    </div>
    <div
      v-if="value || $slots.default"
      class="break-words"
      :class="inline ? 'flex-1 min-w-0 text-sm text-n-slate-12 leading-8' : ''"
    >
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>
