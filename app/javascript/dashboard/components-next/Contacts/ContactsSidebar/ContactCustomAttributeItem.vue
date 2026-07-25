<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import ListAttribute from 'dashboard/components-next/CustomAttributes/ListAttribute.vue';
import CheckboxAttribute from 'dashboard/components-next/CustomAttributes/CheckboxAttribute.vue';
import DateAttribute from 'dashboard/components-next/CustomAttributes/DateAttribute.vue';
import OtherAttribute from 'dashboard/components-next/CustomAttributes/OtherAttribute.vue';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
import Button from 'dashboard/components-next/button/Button.vue';

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

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const isFieldFocused = ref(false);

const handleDelete = async () => {
  try {
    await store.dispatch('contacts/deleteCustomAttributes', {
      id: route.params.contactId,
      customAttributes: [props.attribute.attributeKey],
    });
    useAlert(
      t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.DELETE_SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.DELETE_ERROR')
    );
  }
};

const handleUpdate = async value => {
  try {
    await store.dispatch('contacts/update', {
      id: route.params.contactId,
      customAttributes: {
        [props.attribute.attributeKey]: value,
      },
    });
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.UPDATE_ERROR')
    );
  }
};

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  datetime: DateAttribute,
  default: OtherAttribute,
};

const CurrentAttributeComponent = computed(() => {
  return (
    componentMap[props.attribute.attributeDisplayType] || componentMap.default
  );
});

const isCheckbox = computed(
  () => props.attribute.attributeDisplayType === 'checkbox'
);

const isReadOnly = computed(() => !!props.attribute.formula);

const hasValue = computed(() => {
  const val = props.attribute.value;
  if (Array.isArray(val)) return val.length > 0;
  if (typeof val === 'boolean') return val;
  return val !== null && val !== undefined && val !== '';
});

const description = computed(
  () =>
    props.attribute.attributeDescription ||
    props.attribute.attribute_description ||
    ''
);

const onUpdate = value => {
  if (isReadOnly.value) return;
  handleUpdate(value);
};

const onDelete = () => {
  if (isReadOnly.value) return;
  handleDelete();
};
</script>

<template>
  <!-- Checkbox: compact row -->
  <div
    v-if="isCheckbox"
    class="flex items-center gap-2 w-full min-h-9 px-1 group/attribute"
  >
    <span
      class="flex-1 min-w-0 text-sm font-medium text-n-slate-12 truncate"
      :title="description || attribute.attributeDisplayName"
    >
      {{ attribute.attributeDisplayName }}
    </span>
    <CheckboxAttribute
      :attribute="attribute"
      :is-editing-view="isEditingView && !isReadOnly"
      @update="onUpdate"
      @delete="onDelete"
    />
  </div>

  <!-- Outlined floating label for all other types -->
  <OutlinedAttributeField
    v-else
    class="group/attribute"
    :label="attribute.attributeDisplayName"
    :description="description"
    :filled="hasValue || isFieldFocused"
    :focused="isFieldFocused"
  >
    <component
      :is="CurrentAttributeComponent"
      :attribute="attribute"
      :is-editing-view="isEditingView && !isReadOnly"
      :read-only="isReadOnly"
      @update="onUpdate"
      @focus-change="val => (isFieldFocused = val)"
    />
    <template v-if="isEditingView && hasValue && !isReadOnly" #trailing>
      <Button
        variant="ghost"
        color="slate"
        icon="i-lucide-trash-2"
        size="xs"
        @click="onDelete"
      />
    </template>
  </OutlinedAttributeField>
</template>
