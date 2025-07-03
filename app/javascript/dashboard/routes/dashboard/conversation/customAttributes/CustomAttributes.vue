<script setup>
import { computed, onMounted, ref } from 'vue';
import Draggable from 'vuedraggable';
import { useToggle } from '@vueuse/core';
import { useRoute } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
  // Combine static elements with custom attributes components
  // To allow for custom ordering
  staticElements: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();
const getters = useStoreGetters();
const route = useRoute();
const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const dragging = ref(false);

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

const filteredCustomAttributes = computed(() =>
  attributes.value.map(attribute => {
    // Check if the attribute key exists in customAttributes
    const hasValue = Object.hasOwnProperty.call(
      customAttributes.value,
      attribute.attribute_key
    );

    return {
      ...attribute,
      type: 'custom_attribute',
      key: attribute.attribute_key,
      // Set value from customAttributes if it exists, otherwise use ''
      value: hasValue ? customAttributes.value[attribute.attribute_key] : '',
    };
  })
);

// Order key name for UI settings
const orderKey = computed(
  () => `conversation_elements_order_${props.attributeFrom}`
);

const combinedElements = computed(() => {
  // Get saved order from UI settings
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const allElements = [
    ...props.staticElements,
    ...filteredCustomAttributes.value,
  ];

  // If no saved order exists, return in default order
  if (!savedOrder.length) return allElements;

  return allElements.sort((a, b) => {
    // Find positions of elements in saved order
    const aPosition = savedOrder.indexOf(a.key);
    const bPosition = savedOrder.indexOf(b.key);

    // Handle cases where elements are not in saved order:
    // - New elements (not in saved order) go to the end
    // - If both elements are new, maintain their relative order
    if (aPosition === -1 && bPosition === -1) return 0;
    if (aPosition === -1) return 1;
    if (bPosition === -1) return -1;

    return aPosition - bPosition;
  });
});

const displayedElements = computed(() => {
  if (showAllAttributes.value || combinedElements.value.length <= 5) {
    return combinedElements.value;
  }

  // Show first 5 elements in the order they appear
  return combinedElements.value.slice(0, 5);
});

// Reorder elements with static elements position preserved
// There is case where all the static elements will not be available (API, Email channels, etc).
// In that case, we need to preserve the order of the static elements and
// insert them in the correct position.
const reorderElementsWithStaticPreservation = (
  savedOrder = [],
  currentOrder = []
) => {
  const finalOrder = [...currentOrder];
  const visibleKeys = new Set(currentOrder);

  // Process hidden static elements from saved order
  savedOrder
    // Find static elements that aren't currently visible
    .filter(key => key.startsWith('static-') && !visibleKeys.has(key))
    .forEach(staticKey => {
      // Find next visible element after this static element in saved order
      const nextVisible = savedOrder
        .slice(savedOrder.indexOf(staticKey))
        .find(key => visibleKeys.has(key));

      // If next visible element found, insert before it; otherwise add to end
      if (nextVisible) {
        finalOrder.splice(finalOrder.indexOf(nextVisible), 0, staticKey);
      } else {
        finalOrder.push(staticKey);
      }
    });

  return finalOrder;
};

const onDragEnd = () => {
  dragging.value = false;
  // Get the saved and current saved order
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const currentOrder = combinedElements.value.map(({ key }) => key);

  const finalOrder = reorderElementsWithStaticPreservation(
    savedOrder,
    currentOrder
  );

  updateUISettings({
    [orderKey.value]: finalOrder,
  });
};

const initializeSettings = () => {
  const currentOrder = uiSettings.value[orderKey.value];
  if (!currentOrder) {
    const initialOrder = combinedElements.value.map(element => element.key);
    updateUISettings({
      [orderKey.value]: initialOrder,
    });
  }

  showAllAttributes.value =
    uiSettings.value[`show_all_attributes_${props.attributeFrom}`] || false;
};

const onClickToggle = () => {
  toggleShowAllAttributes();
  updateUISettings({
    [`show_all_attributes_${props.attributeFrom}`]: showAllAttributes.value,
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
        customAttributes: updatedAttributes,
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
  '[&>*:nth-child(odd)]:!bg-n-background [&>*:nth-child(even)]:!bg-n-slate-2',
  'dark:[&>*:nth-child(odd)]:!bg-n-background dark:[&>*:nth-child(even)]:!bg-n-solid-1',
];
</script>

<template>
  <div class="conversation--details">
    <Draggable
      :list="displayedElements"
      :disabled="!showAllAttributes"
      animation="200"
      ghost-class="ghost"
      handle=".drag-handle"
      item-key="key"
      class="last:rounded-b-lg"
      :class="evenClass"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <template #item="{ element }">
        <div
          class="drag-handle relative border-b border-n-weak/50 dark:border-n-weak/90"
          :class="{
            'cursor-grab': showAllAttributes,
            'last:border-transparent dark:last:border-transparent':
              combinedElements.length <= 5,
          }"
        >
          <template v-if="element.type === 'static_attribute'">
            <slot name="staticItem" :element="element" />
          </template>

          <template v-else>
            <CustomAttribute
              :key="element.id"
              :attribute-key="element.attribute_key"
              :attribute-type="element.attribute_display_type"
              :values="element.attribute_values"
              :label="element.attribute_display_name"
              :description="element.attribute_description"
              :value="element.value"
              show-actions
              :attribute-regex="element.regex_pattern"
              :regex-cue="element.regex_cue"
              :contact-id="contactId"
              @update="onUpdate"
              @delete="onDelete"
              @copy="onCopy"
            />
          </template>
        </div>
      </template>
    </Draggable>

    <p
      v-if="!displayedElements.length && emptyStateMessage"
      class="p-3 text-center"
    >
      {{ emptyStateMessage }}
    </p>
    <!-- Show more and show less buttons show it if the combinedElements length is greater than 5 -->
    <div v-if="combinedElements.length > 5" class="flex items-center px-2 py-2">
      <NextButton
        ghost
        xs
        :icon="
          showAllAttributes ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
        "
        :label="toggleButtonText"
        @click="onClickToggle"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
