<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { parseSenderListValues } from 'dashboard/constants/senderLists';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  listType: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const inputValue = ref('');
const errors = ref([]);
const deletingId = ref(null);
const isSubmitting = ref(false);

const entriesByType = useMapGetter('senderListEntries/getEntriesByType');

const entries = computed(() => entriesByType.value(props.listType));
const parsedValues = computed(() => parseSenderListValues(inputValue.value));

const addEntries = async () => {
  if (!parsedValues.value.length) return;

  isSubmitting.value = true;
  try {
    errors.value = await store.dispatch('senderListEntries/create', {
      listType: props.listType,
      values: parsedValues.value,
    });
    // Rejected values stay in the field so they can be corrected without retyping the batch.
    if (!errors.value.length) inputValue.value = '';
  } catch (error) {
    useAlert(t('SENDER_LISTS.API.CREATE_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const removeEntry = async entry => {
  deletingId.value = entry.id;
  try {
    await store.dispatch('senderListEntries/delete', entry.id);
  } catch (error) {
    useAlert(t('SENDER_LISTS.API.DELETE_ERROR'));
  } finally {
    deletingId.value = null;
  }
};
</script>

<template>
  <section class="flex flex-col gap-3">
    <div class="flex flex-col gap-1">
      <h2 class="text-heading-3 text-n-slate-12">{{ title }}</h2>
      <p class="mb-0 text-body-main text-n-slate-11">{{ description }}</p>
    </div>

    <form class="flex items-center gap-2" @submit.prevent="addEntries">
      <Input
        v-model="inputValue"
        size="sm"
        class="w-full max-w-md"
        :aria-label="$t('SENDER_LISTS.FORM.ARIA_LABEL', { list: title })"
        :placeholder="$t('SENDER_LISTS.FORM.PLACEHOLDER')"
      />
      <Button
        type="submit"
        size="sm"
        :label="$t('SENDER_LISTS.FORM.ADD')"
        :is-loading="isSubmitting"
        :disabled="!parsedValues.length || isSubmitting"
      />
    </form>

    <ul v-if="errors.length" class="flex flex-col gap-1 list-none">
      <li
        v-for="error in errors"
        :key="error.value"
        class="text-body-main text-n-ruby-11"
      >
        {{ $t('SENDER_LISTS.FORM.ERROR', error) }}
      </li>
    </ul>

    <div v-if="entries.length" class="flex flex-wrap gap-2">
      <span
        v-for="entry in entries"
        :key="entry.id"
        class="inline-flex items-center h-8 gap-1 text-sm rounded-lg ltr:pl-3 ltr:pr-1 rtl:pr-3 rtl:pl-1 bg-n-alpha-2 text-n-slate-12"
      >
        {{ entry.value }}
        <Button
          v-tooltip.top="$t('SENDER_LISTS.FORM.REMOVE')"
          icon="i-lucide-x"
          slate
          ghost
          xs
          :is-loading="deletingId === entry.id"
          @click="removeEntry(entry)"
        />
      </span>
    </div>
    <p v-else class="mb-0 text-body-main text-n-slate-10">
      {{ $t('SENDER_LISTS.EMPTY') }}
    </p>
  </section>
</template>
