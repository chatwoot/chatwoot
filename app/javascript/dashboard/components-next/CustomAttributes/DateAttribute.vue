<script setup>
import { ref, computed, watch } from 'vue';
import { parseISO } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  readOnly: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'focusChange']);

const { t } = useI18n();

const isDatetime = computed(
  () => props.attribute.attributeDisplayType === 'datetime'
);

const isEditingValue = ref(false);
const editedValue = ref(props.attribute.value || '');

watch(
  () => props.attribute.value,
  val => {
    if (!isEditingValue.value) editedValue.value = val || '';
  }
);

const rules = {
  editedValue: {
    required,
    isDate: value => new Date(value).toISOString(),
  },
};

const v$ = useVuelidate(rules, { editedValue });

const toDatetimeLocalValue = date => {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return '';
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const formattedDate = computed(() => {
  if (!props.attribute.value) return '';
  const date = new Date(props.attribute.value);
  if (Number.isNaN(date.getTime())) return String(props.attribute.value);
  return isDatetime.value ? date.toLocaleString() : date.toLocaleDateString();
});

const hasError = computed(() => v$.value.$errors.length > 0);

const defaultDateValue = computed({
  get() {
    const existingDate = editedValue.value ?? props.attribute.value;
    if (existingDate) {
      return isDatetime.value
        ? toDatetimeLocalValue(existingDate)
        : new Date(existingDate).toISOString().slice(0, 10);
    }
    if (isEditingValue.value && !hasError.value) {
      return isDatetime.value
        ? toDatetimeLocalValue(new Date())
        : new Date().toISOString().slice(0, 10);
    }
    return '';
  },
  set(value) {
    editedValue.value = value ? new Date(value).toISOString() : value;
  },
});

const toggleEditValue = value => {
  if (props.readOnly) return;
  isEditingValue.value =
    typeof value === 'boolean' ? value : !isEditingValue.value;
  emit('focusChange', isEditingValue.value);

  if (isEditingValue.value && !editedValue.value) {
    v$.value.$reset();
    editedValue.value = new Date().toISOString();
  }
};

const handleInputUpdate = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  emit('update', parseISO(editedValue.value));
  toggleEditValue(false);
};

const onClickAway = () => {
  v$.value.$reset();
  toggleEditValue(false);
};
</script>

<template>
  <div class="flex items-center w-full min-w-0">
    <span
      v-if="!isEditingValue"
      class="min-w-0 text-sm text-n-slate-12 truncate min-h-8 flex items-center w-full"
      :class="{ 'opacity-0': !formattedDate, 'cursor-pointer': !readOnly }"
      @click="toggleEditValue(true)"
    >
      {{ formattedDate || '\u00A0' }}
    </span>

    <div
      v-else
      v-on-clickaway="onClickAway"
      class="flex flex-col w-full min-w-0"
    >
      <div class="flex items-center w-full gap-1">
        <input
          v-model="defaultDateValue"
          :type="isDatetime ? 'datetime-local' : 'date'"
          class="!mb-0 !h-8 !border-0 !shadow-none !outline-none !bg-transparent !px-0 !text-sm w-full"
          autofocus
          @keyup.enter="handleInputUpdate"
        />
        <Button
          icon="i-lucide-check"
          :color="hasError ? 'ruby' : 'blue'"
          size="sm"
          class="flex-shrink-0"
          @click="handleInputUpdate"
        />
      </div>
      <span v-if="hasError" class="text-xs text-n-ruby-11 mt-0.5">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.INVALID_DATE') }}
      </span>
    </div>
  </div>
</template>
