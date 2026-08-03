<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
});
const emit = defineEmits(['update:modelValue']);
const BODY_TEXT_MAX_LENGTH = 1024;
const HEADER_TEXT_MAX_LENGTH = 60;
const FOOTER_TEXT_MAX_LENGTH = 60;
const LIST_BUTTON_TEXT_MAX_LENGTH = 20;
const SECTION_TITLE_MAX_LENGTH = 24;
const ROW_TITLE_MAX_LENGTH = 24;
const ROW_DESCRIPTION_MAX_LENGTH = 72;
const MAX_SECTIONS = 10;
// WhatsApp caps the combined row count across all sections at 10, not per section.
const MAX_TOTAL_ROWS = 10;

const { t } = useI18n();

const totalRows = computed(() =>
  props.modelValue.sections.reduce(
    (count, section) => count + section.rows.length,
    0
  )
);

const updateField = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value });
};

const updateSections = sections => updateField('sections', sections);

const updateSection = (index, section) => {
  updateSections(
    props.modelValue.sections.map((existing, sectionIndex) =>
      sectionIndex === index ? section : existing
    )
  );
};

const addSection = () => {
  if (
    props.modelValue.sections.length >= MAX_SECTIONS ||
    totalRows.value >= MAX_TOTAL_ROWS
  ) {
    return;
  }
  updateSections([
    ...props.modelValue.sections,
    { title: '', rows: [{ title: '', description: '' }] },
  ]);
};

const removeSection = index => {
  updateSections(
    props.modelValue.sections.filter(
      (_, sectionIndex) => sectionIndex !== index
    )
  );
};

const addRow = sectionIndex => {
  if (totalRows.value >= MAX_TOTAL_ROWS) return;
  const section = props.modelValue.sections[sectionIndex];
  updateSection(sectionIndex, {
    ...section,
    rows: [...section.rows, { title: '', description: '' }],
  });
};

const removeRow = (sectionIndex, rowIndex) => {
  const section = props.modelValue.sections[sectionIndex];
  updateSection(sectionIndex, {
    ...section,
    rows: section.rows.filter((_, index) => index !== rowIndex),
  });
};

const updateRow = (sectionIndex, rowIndex, field, value) => {
  const section = props.modelValue.sections[sectionIndex];
  updateSection(sectionIndex, {
    ...section,
    rows: section.rows.map((row, index) =>
      index === rowIndex ? { ...row, [field]: value } : row
    ),
  });
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <TextArea
      :model-value="modelValue.bodyText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT_PLACEHOLDER')"
      :max-length="BODY_TEXT_MAX_LENGTH"
      show-character-count
      auto-height
      @update:model-value="value => updateField('bodyText', value)"
    />
    <Input
      :model-value="modelValue.headerText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.HEADER_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.HEADER_TEXT_PLACEHOLDER')"
      :maxlength="HEADER_TEXT_MAX_LENGTH"
      @update:model-value="value => updateField('headerText', value)"
    />
    <Input
      :model-value="modelValue.footerText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT_PLACEHOLDER')"
      :maxlength="FOOTER_TEXT_MAX_LENGTH"
      @update:model-value="value => updateField('footerText', value)"
    />
    <Input
      :model-value="modelValue.listButtonText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.LIST_BUTTON_TEXT')"
      :placeholder="
        t('INTERACTIVE_MESSAGES.FIELDS.LIST_BUTTON_TEXT_PLACEHOLDER')
      "
      :maxlength="LIST_BUTTON_TEXT_MAX_LENGTH"
      @update:model-value="value => updateField('listButtonText', value)"
    />

    <div class="flex flex-col gap-3">
      <div
        v-for="(section, sectionIndex) in modelValue.sections"
        :key="sectionIndex"
        class="flex flex-col gap-3 p-4 rounded-lg bg-n-alpha-1"
      >
        <div class="flex items-center gap-2">
          <Input
            :model-value="section.title"
            class="flex-1"
            :label="t('INTERACTIVE_MESSAGES.FIELDS.SECTION_TITLE')"
            :placeholder="
              t('INTERACTIVE_MESSAGES.FIELDS.SECTION_TITLE_PLACEHOLDER')
            "
            :maxlength="SECTION_TITLE_MAX_LENGTH"
            @update:model-value="
              value => updateSection(sectionIndex, { ...section, title: value })
            "
          />
          <Button
            v-if="modelValue.sections.length > 1"
            icon="i-lucide-trash"
            color="ruby"
            variant="faded"
            size="sm"
            class="mt-5"
            :aria-label="t('INTERACTIVE_MESSAGES.BUTTONS.REMOVE_SECTION')"
            @click="removeSection(sectionIndex)"
          />
        </div>

        <div
          v-for="(row, rowIndex) in section.rows"
          :key="rowIndex"
          class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak bg-n-solid-2"
        >
          <div class="flex items-center justify-between">
            <p class="text-xs font-medium text-n-slate-11">
              {{ t('INTERACTIVE_MESSAGES.FIELDS.ROW_TITLE') }}
              {{ rowIndex + 1 }}
            </p>
            <Button
              v-if="section.rows.length > 1"
              icon="i-lucide-trash"
              color="ruby"
              variant="faded"
              size="xs"
              :aria-label="t('INTERACTIVE_MESSAGES.BUTTONS.REMOVE_ROW')"
              @click="removeRow(sectionIndex, rowIndex)"
            />
          </div>
          <Input
            :model-value="row.title"
            :placeholder="
              t('INTERACTIVE_MESSAGES.FIELDS.ROW_TITLE_PLACEHOLDER')
            "
            :maxlength="ROW_TITLE_MAX_LENGTH"
            @update:model-value="
              value => updateRow(sectionIndex, rowIndex, 'title', value)
            "
          />
          <Input
            :model-value="row.description"
            :placeholder="
              t('INTERACTIVE_MESSAGES.FIELDS.ROW_DESCRIPTION_PLACEHOLDER')
            "
            :maxlength="ROW_DESCRIPTION_MAX_LENGTH"
            @update:model-value="
              value => updateRow(sectionIndex, rowIndex, 'description', value)
            "
          />
        </div>

        <Button
          v-if="totalRows < MAX_TOTAL_ROWS"
          icon="i-lucide-plus"
          color="slate"
          variant="faded"
          size="sm"
          class="self-start"
          :label="t('INTERACTIVE_MESSAGES.BUTTONS.ADD_ROW')"
          @click="addRow(sectionIndex)"
        />
      </div>

      <Button
        v-if="
          modelValue.sections.length < MAX_SECTIONS &&
          totalRows < MAX_TOTAL_ROWS
        "
        icon="i-lucide-plus"
        color="slate"
        variant="faded"
        size="sm"
        class="self-start"
        :label="t('INTERACTIVE_MESSAGES.BUTTONS.ADD_SECTION')"
        @click="addSection"
      />
      <p v-if="totalRows >= MAX_TOTAL_ROWS" class="text-xs text-n-slate-11">
        {{ t('INTERACTIVE_MESSAGES.BUTTONS.MAX_ROWS_REACHED') }}
      </p>
    </div>
  </div>
</template>
