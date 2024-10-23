<script setup>
import { computed, onMounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useRoute } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';

const props = defineProps({
  attributeType: {
    type: String,
    default: 'conversation_attribute',
  },
  contactId: { type: Number, default: null },
  attributeFrom: {
    type: String,
    required: true,
  },
  emptyStateMessage: {
    type: String,
    default: '',
  },
  startAt: {
    type: String,
    default: 'even',
    validator: value => value === 'even' || value === 'odd',
  },
});

const store = useStore();
const getters = useStoreGetters();
const route = useRoute();
const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const [showAllAttributes, toggleShowAllAttributes] = useToggle(false);

const currentChat = computed(() => getters.getSelectedChat.value);
const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(props.attributeType)
);

const contactIdentifier = computed(
  () =>
    currentChat.value.meta?.sender?.id ||
    route.params.contactId ||
    props.contactId
);

const contact = computed(() =>
  getters['contacts/getContact'].value(contactIdentifier.value)
);

const customAttributes = computed(() => {
  if (props.attributeType === 'conversation_attribute')
    return currentChat.value.custom_attributes || {};
  return contact.value.custom_attributes || {};
});

const conversationId = computed(() => currentChat.value.id);

const toggleButtonText = computed(() =>
  !showAllAttributes.value
    ? t('CUSTOM_ATTRIBUTES.SHOW_MORE')
    : t('CUSTOM_ATTRIBUTES.SHOW_LESS')
);

const filteredAttributes = computed(() =>
  attributes.value.map(attribute => {
    // Check if the attribute key exists in customAttributes
    const hasValue = Object.hasOwnProperty.call(
      customAttributes.value,
      attribute.attribute_key
    );
    const isCheckbox = attribute.attribute_display_type === 'checkbox';
    const defaultValue = isCheckbox ? false : '';

    return {
      ...attribute,
      // Set value from customAttributes if it exists, otherwise use default value
      value: hasValue
        ? customAttributes.value[attribute.attribute_key]
        : defaultValue,
    };
  })
);

const displayedAttributes = computed(() => {
  // Show only the first 5 attributes or all depending on showAllAttributes
  if (showAllAttributes.value || filteredAttributes.value.length <= 5) {
    return filteredAttributes.value;
  }
  return filteredAttributes.value.slice(0, 5);
});

const showMoreUISettingsKey = computed(
  () => `show_all_attributes_${props.attributeFrom}`
);

const initializeSettings = () => {
  showAllAttributes.value =
    uiSettings.value[showMoreUISettingsKey.value] || false;
};

const onClickToggle = () => {
  toggleShowAllAttributes();
  updateUISettings({
    [showMoreUISettingsKey.value]: showAllAttributes.value,
  });
};

const onUpdate = async (key, value) => {
  const updatedAttributes = { ...customAttributes.value, [key]: value };
  try {
    if (props.attributeType === 'conversation_attribute') {
      await store.dispatch('updateCustomAttributes', {
        conversationId: conversationId.value,
        customAttributes: updatedAttributes,
      });
    } else {
      store.dispatch('contacts/update', {
        id: props.contactId,
        custom_attributes: updatedAttributes,
      });
    }
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const onDelete = async key => {
  try {
    const { [key]: remove, ...updatedAttributes } = customAttributes.value;
    if (props.attributeType === 'conversation_attribute') {
      await store.dispatch('updateCustomAttributes', {
        conversationId: conversationId.value,
        customAttributes: updatedAttributes,
      });
    } else {
      store.dispatch('contacts/deleteCustomAttributes', {
        id: props.contactId,
        customAttributes: [key],
      });
    }
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

const onCopy = async attributeValue => {
  await copyTextToClipboard(attributeValue);
  useAlert(t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
};

onMounted(() => {
  initializeSettings();
});

const evenClass = [
  '[&>*:nth-child(odd)]:!bg-white [&>*:nth-child(even)]:!bg-slate-25',
  'dark:[&>*:nth-child(odd)]:!bg-slate-900 dark:[&>*:nth-child(even)]:!bg-slate-800/50',
];
const oddClass = [
  '[&>*:nth-child(odd)]:!bg-slate-25 [&>*:nth-child(even)]:!bg-white',
  'dark:[&>*:nth-child(odd)]:!bg-slate-800/50 dark:[&>*:nth-child(even)]:!bg-slate-900',
];

const wrapperClass = computed(() => {
  return props.startAt === 'even' ? evenClass : oddClass;
});
</script>

<!-- TODO: After migration to Vue 3, remove the top level div -->
<template>
  <div :class="wrapperClass">
    <CustomAttribute
      v-for="attribute in displayedAttributes"
      :key="attribute.id"
      :attribute-key="attribute.attribute_key"
      :attribute-type="attribute.attribute_display_type"
      :values="attribute.attribute_values"
      :label="attribute.attribute_display_name"
      :description="attribute.attribute_description"
      :value="attribute.value"
      show-actions
      :attribute-regex="attribute.regex_pattern"
      :regex-cue="attribute.regex_cue"
      :contact-id="contactId"
      class="border-b border-solid border-slate-50 dark:border-slate-700/50"
      @update="onUpdate"
      @delete="onDelete"
      @copy="onCopy"
    />
    <p
      v-if="!displayedAttributes.length && emptyStateMessage"
      class="p-3 text-center"
    >
      {{ emptyStateMessage }}
    </p>
    <!-- Show more and show less buttons show it if the filteredAttributes length is greater than 5 -->
    <div v-if="filteredAttributes.length > 5" class="flex px-2 py-2">
      <woot-button
        size="small"
        :icon="showAllAttributes ? 'chevron-up' : 'chevron-down'"
        variant="clear"
        color-scheme="primary"
        class="!px-2 hover:!bg-transparent dark:hover:!bg-transparent"
        @click="onClickToggle"
      >
        {{ toggleButtonText }}
      </woot-button>
    </div>
  </div>
</template>
