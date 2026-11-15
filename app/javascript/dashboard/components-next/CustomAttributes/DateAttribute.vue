<script setup>
import { ref, computed } from 'vue';
import { parseISO } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { vOnClickOutside } from '@vueuse/components';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  attributeCalendarDate,
  formatFixed,
  formatLocalized,
} from 'shared/helpers/localizedDate';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  isEditingView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'delete']);

const { t } = useI18n();

const isEditingValue = ref(false);
const editedValue = ref(props.attribute.value || '');
const initialEditValue = ref('');

const rules = {
  editedValue: {
    required,
    isDate: value => new Date(value).toISOString(),
  },
};

const v$ = useVuelidate(rules, { editedValue });

const formattedDate = computed(() => {
  return props.attribute.value
    ? formatLocalized(attributeCalendarDate(props.attribute.value), 'M/d/yyyy')
    : t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.INPUT');
});

const hasError = computed(() => v$.value.$errors.length > 0);

const defaultDateValue = computed({
  get() {
    // The same calendar day the attribute is shown with.
    const existingDate = editedValue.value ?? props.attribute.value;
    if (existingDate) {
      return formatFixed(attributeCalendarDate(existingDate), 'yyyy-MM-dd');
    }
    return isEditingValue.value && !hasError.value
      ? formatFixed(new Date(), 'yyyy-MM-dd')
      : '';
  },
  set(value) {
    editedValue.value = value ? new Date(value).toISOString() : value;
  },
});

const toggleEditValue = value => {
  isEditingValue.value =
    typeof value === 'boolean' ? value : !isEditingValue.value;

  if (isEditingValue.value && !editedValue.value) {
    v$.value.$reset();
    editedValue.value = new Date().toISOString();
  }
  if (isEditingValue.value) {
    initialEditValue.value = editedValue.value;
  }
};

const handleInputUpdate = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  emit('update', parseISO(editedValue.value));
  isEditingValue.value = false;
};

const handleClickOutside = () => {
  if (editedValue.value === initialEditValue.value) {
    isEditingValue.value = false;
    return;
  }
  handleInputUpdate();
};
</script>

<template>
  <div
    class="flex items-center w-full min-w-0 gap-2"
    :class="{
      'justify-start': isEditingView,
      'justify-end': !isEditingView,
    }"
  >
    <span
      v-if="!isEditingValue"
      class="min-w-0 text-sm"
      :class="{
        'cursor-pointer text-n-slate-11 hover:text-n-slate-12 py-2 select-none font-medium':
          !isEditingView,
        'text-n-slate-12 truncate': isEditingView,
      }"
      @click="toggleEditValue(!isEditingView)"
    >
      {{ formattedDate }}
    </span>

    <div
      v-if="isEditingView && !isEditingValue"
      class="flex items-center gap-1"
    >
      <Button
        variant="faded"
        color="slate"
        icon="i-lucide-pencil"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="toggleEditValue(true)"
      />
      <Button
        variant="faded"
        color="ruby"
        icon="i-lucide-trash"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="emit('delete')"
      />
    </div>

    <div
      v-if="isEditingValue"
      v-on-click-outside="handleClickOutside"
      class="flex items-center w-full"
    >
      <Input
        v-model="defaultDateValue"
        type="date"
        class="w-full [&>p]:absolute [&>p]:mt-0.5 [&>p]:top-8 ltr:[&>p]:left-0 rtl:[&>p]:right-0"
        :message="
          hasError
            ? t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.INVALID_DATE')
            : ''
        "
        :message-type="hasError ? 'error' : 'info'"
        autofocus
        custom-input-class="h-8 ltr:rounded-r-none rtl:rounded-l-none"
        @enter="handleInputUpdate"
      />
      <Button
        icon="i-lucide-check"
        :color="hasError ? 'ruby' : 'blue'"
        size="sm"
        class="flex-shrink-0 ltr:rounded-l-none rtl:rounded-r-none"
        @click="handleInputUpdate"
      />
    </div>
  </div>
</template>
