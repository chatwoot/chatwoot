<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { MESSAGE_VARIABLES } from 'shared/constants/messages';
import { useMapGetter } from 'dashboard/composables/store';
import { sanitizeVariableSearchKey } from 'dashboard/helper/commons';
import {
  resolveVariableText,
  variableContent,
} from 'dashboard/helper/editorHelper';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  searchKey: {
    type: String,
    default: '',
  },
  variables: {
    type: Object,
    default: () => ({}),
  },
  // Text of an automation rule is rendered when the rule runs, which also knows the conversation's
  // assignee and the state it was in before the run (`conversation.before`).
  automation: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'selectVariable',
  'close',
  'removeTrigger',
  'release',
]);

const { t } = useI18n();

const customAttributes = useMapGetter('attributes/getAttributes');

// The search starts with the variable only: the punctuation after `{{contact.name}}.` is text
// of the message, and would otherwise be handed back into the variable when the search is edited.
const initialQuery = sanitizeVariableSearchKey(
  variableContent(props.searchKey)
);
const searchQuery = ref(initialQuery);

const searchTerm = computed(() => searchQuery.value.trim().toLowerCase());

const standardVariables = computed(() =>
  MESSAGE_VARIABLES.map(({ key, label }) => ({ key, description: label }))
);

const CUSTOM_ATTRIBUTE_PREFIXES = {
  conversation_attribute: 'conversation',
  contact_attribute: 'contact',
};

const customVariables = computed(() =>
  customAttributes.value
    .filter(attribute => CUSTOM_ATTRIBUTE_PREFIXES[attribute.attribute_model])
    .map(attribute => ({
      key: `${CUSTOM_ATTRIBUTE_PREFIXES[attribute.attribute_model]}.custom_attribute.${attribute.attribute_key}`,
      description: attribute.attribute_description,
    }))
);

const automationVariables = computed(() => {
  if (!props.automation) return [];

  const conversationAttributes = customAttributes.value.filter(
    attribute => attribute.attribute_model === 'conversation_attribute'
  );
  return [
    {
      key: 'conversation.assignee.name',
      description: t('CONVERSATION.PICKER.VARIABLE.AUTOMATION.ASSIGNEE_NAME'),
    },
    {
      key: 'conversation.before.assignee.name',
      description: t(
        'CONVERSATION.PICKER.VARIABLE.AUTOMATION.BEFORE_ASSIGNEE_NAME'
      ),
    },
    ...conversationAttributes.map(attribute => ({
      key: `conversation.before.custom_attribute.${attribute.attribute_key}`,
      description: t(
        'CONVERSATION.PICKER.VARIABLE.AUTOMATION.BEFORE_ATTRIBUTE',
        {
          name: attribute.attribute_display_name,
        }
      ),
    })),
  ];
});

const items = computed(() =>
  [
    ...standardVariables.value,
    ...automationVariables.value,
    ...customVariables.value,
  ]
    .filter(
      ({ key, description }) =>
        key.toLowerCase().includes(searchTerm.value) ||
        description?.toLowerCase().includes(searchTerm.value)
    )
    .map(({ key, description }) => ({
      id: key,
      key,
      label: `{{${key}}}`,
      title: key,
      subtitle: description,
    }))
);

const resolvedValue = key => resolveVariableText(key, props.variables);

const hasValue = key => resolvedValue(key) !== `{{${key}}}`;

const onSelect = item => emit('selectVariable', item.key);
</script>

<template>
  <CaretAnchoredPicker
    v-model:search="searchQuery"
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('CONVERSATION.PICKER.VARIABLE.SEARCH_PLACEHOLDER')"
    :empty-label="t('COMBOBOX.EMPTY_STATE')"
    @select="onSelect"
    @close="emit('close')"
    @remove-trigger="emit('removeTrigger')"
    @release="emit('release', $event)"
  >
    <template #preview="{ item }">
      <div v-if="item" class="flex flex-col gap-3 px-4 py-3">
        <div v-if="item.subtitle" class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-10">
            {{ t('CONVERSATION.PICKER.VARIABLE.DESCRIPTION') }}
          </span>
          <span class="text-sm text-n-slate-12">{{ item.subtitle }}</span>
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-10">
            {{ t('CONVERSATION.PICKER.VARIABLE.VALUE') }}
          </span>
          <span
            class="text-sm break-words"
            :class="hasValue(item.key) ? 'text-n-slate-12' : 'text-n-slate-10'"
          >
            {{
              hasValue(item.key)
                ? resolvedValue(item.key)
                : t('CONVERSATION.PICKER.VARIABLE.NO_VALUE')
            }}
          </span>
        </div>
      </div>
    </template>
  </CaretAnchoredPicker>
</template>
