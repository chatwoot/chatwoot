<script setup>
import Switch from 'dashboard/components-next/switch/Switch.vue';

// One catalog field of the session form: a switch for a boolean, an input for the rest.
const props = defineProps({
  field: { type: Object, required: true },
  error: { type: Boolean, default: false },
});
const emit = defineEmits(['blur']);
const value = defineModel({ type: [String, Boolean, Number], default: '' });

const fieldKey = `INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.${props.field.name.toUpperCase()}`;
const inputType = props.field.type === 'password' ? 'password' : 'text';
</script>

<template>
  <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
    <label v-if="field.type === 'boolean'">
      <div class="flex mb-2 items-center">
        <span class="mr-2 text-sm">
          {{ $t(`${fieldKey}.LABEL`) }}
        </span>
        <Switch :id="field.name" v-model="value" />
      </div>
    </label>
    <label v-else :class="{ error }">
      {{ $t(`${fieldKey}.LABEL`) }}
      <input
        v-model="value"
        :data-field="field.name"
        :type="inputType"
        :placeholder="$t(`${fieldKey}.PLACEHOLDER`)"
        @blur="emit('blur')"
      />
      <span v-if="error" class="message">
        {{ $t(`${fieldKey}.ERROR`) }}
      </span>
    </label>
  </div>
</template>
