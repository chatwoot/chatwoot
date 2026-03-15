<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const aliasRows = computed(() =>
  props.modelValue
    .map((row, index) => ({ ...row, index }))
    .filter(row => !row.primary)
);

const updateRows = rows => emit('update:modelValue', rows);

const addAlias = () => {
  updateRows([...props.modelValue, { email: '', primary: false }]);
};

const updateAliasEmail = (index, email) => {
  updateRows(
    props.modelValue.map((row, rowIndex) =>
      rowIndex === index ? { ...row, email } : row
    )
  );
};

const removeAlias = index => {
  updateRows(props.modelValue.filter((_, rowIndex) => rowIndex !== index));
};

const setPrimary = index => {
  updateRows(
    props.modelValue.map((row, rowIndex) => ({
      ...row,
      primary: rowIndex === index,
    }))
  );
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex items-center justify-between gap-3">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.TITLE') }}
      </span>
      <button
        type="button"
        data-testid="contact-email-add"
        class="inline-flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-n-brand hover:bg-n-alpha-2"
        @click="addAlias"
      >
        <span class="i-ph-plus size-4" />
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.ADD') }}
      </button>
    </div>

    <div v-if="aliasRows.length" class="flex flex-col gap-3">
      <div
        v-for="row in aliasRows"
        :key="`${row.index}-${row.email}`"
        :data-testid="`contact-email-alias-${row.index}`"
        class="flex flex-col gap-3 rounded-xl border border-n-weak bg-n-alpha-2 p-3"
      >
        <input
          :value="row.email"
          type="email"
          :data-testid="`contact-email-alias-input-${row.index}`"
          class="h-10 rounded-lg border border-n-weak bg-n-background px-3 text-sm text-n-slate-12 outline-none transition hover:border-n-slate-6 focus:border-n-brand"
          :placeholder="
            t(
              'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.PLACEHOLDER'
            )
          "
          @input="updateAliasEmail(row.index, $event.target.value)"
        />
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            :data-testid="`contact-email-primary-${row.index}`"
            class="rounded-lg px-3 py-2 text-sm font-medium text-n-slate-11 hover:bg-n-alpha-3"
            @click="setPrimary(row.index)"
          >
            {{
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.SET_PRIMARY'
              )
            }}
          </button>
          <button
            type="button"
            :data-testid="`contact-email-remove-${row.index}`"
            class="rounded-lg px-3 py-2 text-sm font-medium text-n-ruby-9 hover:bg-ruby-2"
            @click="removeAlias(row.index)"
          >
            {{
              t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.REMOVE')
            }}
          </button>
        </div>
      </div>
    </div>

    <p v-else class="text-sm text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.EMAIL_ALIASES.EMPTY') }}
    </p>
  </div>
</template>
