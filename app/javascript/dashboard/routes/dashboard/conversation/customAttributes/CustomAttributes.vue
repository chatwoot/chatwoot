<script setup>
import { computed, onMounted, ref } from 'vue';
import Draggable from 'vuedraggable';
import { useToggle } from '@vueuse/core';
import { useRoute } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import NextButton from 'dashboard/components-next/button/Button.vue';
import HelperTextPopup from 'dashboard/components/ui/HelperTextPopup.vue';

import ListAttribute from 'dashboard/components-next/CustomAttributes/ListAttribute.vue';
import CheckboxAttribute from 'dashboard/components-next/CustomAttributes/CheckboxAttribute.vue';
import DateAttribute from 'dashboard/components-next/CustomAttributes/DateAttribute.vue';
import OtherAttribute from 'dashboard/components-next/CustomAttributes/OtherAttribute.vue';
import SidePanelEmptyState from 'dashboard/routes/dashboard/conversation/SidePanelEmptyState.vue';

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
  showTitle: {
    type: Boolean,
    default: false,
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
      id: attribute.id,
      type: 'custom_attribute',
      key: attribute.attribute_key,
      attributeKey: attribute.attribute_key,
      attributeDisplayName: attribute.attribute_display_name,
      attributeDisplayType: attribute.attribute_display_type,
      attributeValues: attribute.attribute_values,
      attributeDescription: attribute.attribute_description,
      regexPattern: attribute.regex_pattern,
      regexCue: attribute.regex_cue,
      // Set value from customAttributes if it exists, otherwise use ''
      value: hasValue ? customAttributes.value[attribute.attribute_key] : '',
    };
  })
);

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  default: OtherAttribute,
};

const getAttributeComponent = attributeType =>
  componentMap[attributeType] || componentMap.default;

const orderKey = computed(
  () => `conversation_elements_order_${props.attributeFrom}`
);

const orderedCustomAttributes = computed(() => {
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  if (!savedOrder.length) return filteredCustomAttributes.value;

  return [...filteredCustomAttributes.value].sort((a, b) => {
    const aPos = savedOrder.indexOf(a.key);
    const bPos = savedOrder.indexOf(b.key);
    // Both new: maintain relative order, new items go to end, otherwise sort by saved position
    if (aPos === -1 && bPos === -1) return 0;
    if (aPos === -1) return 1;
    if (bPos === -1) return -1;
    return aPos - bPos;
  });
});

const displayedCustomAttributes = computed(() =>
  showAllAttributes.value || orderedCustomAttributes.value.length <= 5
    ? orderedCustomAttributes.value
    : orderedCustomAttributes.value.slice(0, 5)
);

const localOrder = ref([]);

const draggableList = computed({
  get() {
    const saved = uiSettings.value[orderKey.value] ?? [];
    if (localOrder.value.length && saved.length) {
      return localOrder.value;
    }
    return displayedCustomAttributes.value;
  },
  set(newOrder) {
    localOrder.value = newOrder;
  },
});

const onDragEnd = () => {
  dragging.value = false;
  updateUISettings({
    [orderKey.value]: localOrder.value.map(({ key }) => key),
  });
  localOrder.value = [];
};

const initializeSettings = () => {
  if (!uiSettings.value[orderKey.value]) {
    updateUISettings({
      [orderKey.value]: orderedCustomAttributes.value.map(({ key }) => key),
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
      await store.dispatch('contacts/update', {
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
      await store.dispatch('contacts/deleteCustomAttributes', {
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

onMounted(() => {
  initializeSettings();
});
</script>

<template>
  <div
    v-if="displayedCustomAttributes.length > 0"
    :class="{ 'mt-2': !showTitle }"
  >
    <div v-if="showTitle" class="py-4 flex items-center gap-2">
      <h3 class="text-xs font-medium uppercase text-n-slate-10">
        {{ $t('CUSTOM_ATTRIBUTES.TITLE') }}
      </h3>
      <div class="flex-1 border-b border-dashed border-n-strong" />
    </div>

    <Draggable
      v-model="draggableList"
      :disabled="!showAllAttributes"
      animation="200"
      ghost-class="ghost"
      handle=".drag-handle"
      item-key="key"
      class="mb-1"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <template #item="{ element }">
        <div
          class="drag-handle relative"
          :class="{
            'cursor-grab': showAllAttributes,
          }"
        >
          <div
            class="grid grid-cols-[auto,auto] group/attribute items-center w-full gap-4 min-h-10"
          >
            <div class="flex items-center gap-1.5 min-w-0">
              <HelperTextPopup
                v-if="element.attributeDescription"
                :message="element.attributeDescription"
              />
              <span class="text-body-main truncate text-n-slate-12">
                {{ element.attributeDisplayName }}
              </span>
            </div>

            <component
              :is="getAttributeComponent(element.attributeDisplayType)"
              :attribute="element"
              is-editing-view
              @update="value => onUpdate(element.attributeKey, value)"
              @delete="onDelete(element.attributeKey)"
            />
          </div>
        </div>
      </template>
    </Draggable>

    <!-- Show more and show less buttons -->
    <div
      v-if="orderedCustomAttributes.length > 5"
      class="flex items-center h-10"
    >
      <NextButton
        link
        sm
        :icon="
          showAllAttributes ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
        "
        :label="toggleButtonText"
        class="!text-n-slate-11 hover:!text-n-slate-12 hover:!no-underline !py-2"
        @click="onClickToggle"
      />
    </div>
  </div>

  <!-- Empty state -->
  <SidePanelEmptyState
    v-if="!displayedCustomAttributes.length && emptyStateMessage"
    :message="emptyStateMessage"
  />
</template>

<style lang="scss" scoped>
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
