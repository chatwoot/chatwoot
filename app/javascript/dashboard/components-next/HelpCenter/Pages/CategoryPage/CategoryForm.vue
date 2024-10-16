<script setup>
import { reactive, ref, watch, computed, defineAsyncComponent } from 'vue';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  activeLocaleCode: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const { t } = useI18n();

const isEmojiPickerOpen = ref(false);

const state = reactive({
  id: '',
  name: '',
  icon: '',
  slug: '',
  description: '',
  locale: '',
});

const rules = {
  name: { required, minLength: minLength(1) },
  slug: { required },
};

const v$ = useVuelidate(rules, state);

const nameError = computed(() =>
  v$.value.name.$error
    ? t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.ERROR')
    : ''
);

const slugError = computed(() =>
  v$.value.slug.$error
    ? t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.ERROR')
    : ''
);

const onClickInsertEmoji = emoji => {
  state.icon = emoji;
  isEmojiPickerOpen.value = false;
};

const handleSubmit = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  emit('submit', { ...state });
};

const handleCancel = () => {
  emit('cancel');
};

watch(
  () => state.name,
  () => {
    state.slug = convertToCategorySlug(state.name);
  }
);

// Initialize form data
if (props.mode === 'edit' && props.selectedCategory) {
  const { id, name, icon, slug, description } = props.selectedCategory;
  Object.assign(state, { id, name, icon, slug, description });
}
state.locale = props.activeLocaleCode;
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="relative">
      <Input
        v-model="state.name"
        :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.LABEL')"
        :placeholder="
          t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.PLACEHOLDER')
        "
        :message="nameError"
        :message-type="nameError ? 'error' : 'info'"
        custom-input-class="!h-10 ltr:pl-12 rtl:pr-12 !bg-slate-25 dark:!bg-slate-900"
      >
        <template #prefix>
          <Button
            :label="state.icon"
            variant="secondary"
            size="icon"
            :icon="!state.icon ? 'emoji-add' : ''"
            class="!h-[38px] !w-[38px] absolute top-[27px] !rounded-[7px] border-0 ltr:left-px rtl:right-px ltr:!rounded-r-none rtl:!rounded-l-none"
            @click="isEmojiPickerOpen = !isEmojiPickerOpen"
          />
        </template>
      </Input>
      <OnClickOutside @trigger="isEmojiPickerOpen = false">
        <EmojiInput
          v-if="isEmojiPickerOpen"
          class="left-0 top-16"
          show-remove-button
          :on-click="onClickInsertEmoji"
        />
      </OnClickOutside>
    </div>
    <Input
      v-model="state.slug"
      :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.LABEL')"
      :placeholder="
        t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.PLACEHOLDER')
      "
      :message="
        slugError
          ? slugError
          : 'app.chatwoot.com/hc/my-portal/en-US/categories/my-slug'
      "
      :message-type="slugError ? 'error' : 'info'"
      custom-input-class="!h-10 !bg-slate-25 dark:!bg-slate-900 "
    />
    <TextArea
      v-model="state.description"
      :label="
        t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.DESCRIPTION.LABEL')
      "
      :placeholder="
        t(
          'HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.DESCRIPTION.PLACEHOLDER'
        )
      "
      show-character-count
      custom-text-area-class="!bg-slate-25 dark:!bg-slate-900 !border-slate-100 dark:!border-slate-700/50"
    />
    <div class="flex items-center justify-between w-full gap-3">
      <Button
        variant="secondary"
        :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.CANCEL')"
        text-variant="default"
        class="w-full"
        @click="handleCancel"
      />
      <Button
        :label="
          t(
            `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.${mode.toUpperCase()}`
          )
        "
        class="w-full"
        @click="handleSubmit"
      />
    </div>
  </div>
</template>
