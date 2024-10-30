<script setup>
import {
  reactive,
  ref,
  watch,
  computed,
  defineAsyncComponent,
  onMounted,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
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
    default: '',
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
  portalName: {
    type: String,
    default: '',
  },
  activeLocaleName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['submit', 'cancel']);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const { t } = useI18n();
const route = useRoute();
const getters = useStoreGetters();

const isCreating = useMapGetter('categories/isCreating');

const isUpdatingCategory = computed(() => {
  const id = props.selectedCategory?.id;
  if (id) return getters['categories/uiFlags'].value(id)?.isUpdating;

  return false;
});

const isEmojiPickerOpen = ref(false);

const state = reactive({
  id: '',
  name: '',
  icon: '',
  slug: '',
  description: '',
  locale: '',
});

const isEditMode = computed(() => props.mode === 'edit');

const rules = {
  name: { required, minLength: minLength(1) },
  slug: { required },
};

const v$ = useVuelidate(rules, state);

const isSubmitDisabled = computed(() => v$.value.$invalid);

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

const slugHelpText = computed(() => {
  const { portalSlug, locale } = route.params;
  return t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.HELP_TEXT', {
    portalSlug,
    localeCode: locale,
    categorySlug: state.slug,
  });
});

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
    if (!isEditMode.value) {
      state.slug = convertToCategorySlug(state.name);
    }
  }
);

watch(
  () => props.selectedCategory,
  newCategory => {
    if (props.mode === 'edit' && newCategory) {
      const { id, name, icon, slug, description } = newCategory;
      Object.assign(state, { id, name, icon, slug, description });
    }
  },
  { immediate: true }
);

onMounted(() => {
  if (props.mode === 'create') {
    state.locale = props.activeLocaleCode;
  }
});

defineExpose({ state, isSubmitDisabled });
</script>

<template>
  <div class="flex flex-col gap-4">
    <div
      class="flex items-center justify-start gap-8 px-4 py-2 border rounded-lg border-n-strong"
    >
      <div class="flex flex-col items-start w-full gap-2 py-2">
        <span class="text-sm font-medium text-n-slate-11">
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.PORTAL') }}
        </span>
        <span class="text-sm text-n-slate-12">
          {{ portalName }}
        </span>
      </div>
      <div class="justify-start w-px h-10 bg-n-strong" />
      <div class="flex flex-col w-full gap-2 py-2">
        <span class="text-sm font-medium text-n-slate-11">
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.LOCALE') }}
        </span>
        <span
          :title="`${activeLocaleName} (${activeLocaleCode})`"
          class="text-sm line-clamp-1 text-n-slate-12"
        >
          {{ `${activeLocaleName} (${activeLocaleCode})` }}
        </span>
      </div>
    </div>
    <div class="flex flex-col gap-4">
      <div class="relative">
        <Input
          v-model="state.name"
          :label="
            t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.LABEL')
          "
          :placeholder="
            t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.PLACEHOLDER')
          "
          :message="nameError"
          :message-type="nameError ? 'error' : 'info'"
          custom-input-class="!h-10 ltr:!pl-12 rtl:!pr-12"
        >
          <template #prefix>
            <OnClickOutside @trigger="isEmojiPickerOpen = false">
              <Button
                :label="state.icon"
                color="slate"
                size="sm"
                :icon="!state.icon ? 'i-lucide-smile-plus' : ''"
                class="!h-[38px] !w-[38px] absolute top-[31px] !outline-none !rounded-[7px] border-0 ltr:left-px rtl:right-px ltr:!rounded-r-none rtl:!rounded-l-none"
                @click="isEmojiPickerOpen = !isEmojiPickerOpen"
              />
              <EmojiInput
                v-if="isEmojiPickerOpen"
                class="left-0 top-16"
                show-remove-button
                :on-click="onClickInsertEmoji"
              />
            </OnClickOutside>
          </template>
        </Input>
      </div>
      <Input
        v-model="state.slug"
        :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.LABEL')"
        :placeholder="
          t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.PLACEHOLDER')
        "
        :disabled="isEditMode"
        :message="slugError ? slugError : slugHelpText"
        :message-type="slugError ? 'error' : 'info'"
        custom-input-class="!h-10"
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
      />
      <div
        v-if="showActionButtons"
        class="flex items-center justify-between w-full gap-3"
      >
        <Button
          variant="faded"
          color="slate"
          :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.CANCEL')"
          class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
          @click="handleCancel"
        />
        <Button
          :label="
            t(
              `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.${mode.toUpperCase()}`
            )
          "
          class="w-full"
          :disabled="isSubmitDisabled || isCreating || isUpdatingCategory"
          :is-loading="isCreating || isUpdatingCategory"
          @click="handleSubmit"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.emoji-dialog::before {
  @apply hidden;
}
</style>
