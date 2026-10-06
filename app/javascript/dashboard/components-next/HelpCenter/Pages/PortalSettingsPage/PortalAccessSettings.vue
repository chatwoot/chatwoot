<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

// Mirrors Portal#visibility.
const VISIBILITY = { PUBLIC: 'public', PASSWORD: 'private_with_password' };

const { t } = useI18n();
const uiFlagsIn = useMapGetter('portals/uiFlagsIn');

const savedVisibility = computed(
  () => props.activePortal?.config?.visibility || VISIBILITY.PUBLIC
);

const isUpdatingPortal = computed(
  () => uiFlagsIn.value(props.activePortal?.slug)?.isUpdating
);

const state = reactive({ visibility: VISIBILITY.PUBLIC, password: '' });

watch(
  () => props.activePortal,
  () => {
    state.visibility = savedVisibility.value;
    state.password = '';
  },
  { immediate: true, deep: true }
);

const visibilityOptions = computed(() => [
  {
    value: VISIBILITY.PUBLIC,
    label: t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PUBLIC.LABEL'),
    description: t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PUBLIC.DESCRIPTION'),
  },
  {
    value: VISIBILITY.PASSWORD,
    label: t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD.LABEL'),
    description: t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD.DESCRIPTION'),
  },
]);

const isPasswordProtected = computed(
  () => state.visibility === VISIBILITY.PASSWORD
);

// A portal that is already protected keeps its password unless a new one is typed.
const hasSavedPassword = computed(
  () => savedVisibility.value === VISIBILITY.PASSWORD
);

const isPasswordMissing = computed(
  () => isPasswordProtected.value && !hasSavedPassword.value && !state.password
);

const hasChanges = computed(
  () =>
    state.visibility !== savedVisibility.value ||
    (isPasswordProtected.value && state.password !== '')
);

const passwordMessage = computed(() =>
  hasSavedPassword.value
    ? t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD_FIELD.CHANGE_HELP')
    : t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD_FIELD.HELP')
);

const handleSave = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    // `password` is not a portal column, so Rails only picks it up nested under `portal`.
    portal: {
      config: { visibility: state.visibility },
      ...(isPasswordProtected.value &&
        state.password && { password: state.password }),
    },
  });
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.HEADER') }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.DESCRIPTION') }}
      </span>
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <RadioCard
        v-for="option in visibilityOptions"
        :id="option.value"
        :key="option.value"
        name="portal-visibility"
        :label="option.label"
        :description="option.description"
        :is-active="state.visibility === option.value"
        @select="value => (state.visibility = value)"
      />
    </div>

    <Input
      v-if="isPasswordProtected"
      v-model="state.password"
      type="password"
      :label="t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD_FIELD.LABEL')"
      :placeholder="
        t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.PASSWORD_FIELD.PLACEHOLDER')
      "
      :message="passwordMessage"
    />

    <div class="flex justify-end">
      <Button
        :label="t('HELP_CENTER.PORTAL_SETTINGS.ACCESS.SAVE')"
        :disabled="
          !hasChanges || isPasswordMissing || isFetching || isUpdatingPortal
        "
        :is-loading="isUpdatingPortal"
        @click="handleSave"
      />
    </div>
  </div>
</template>
