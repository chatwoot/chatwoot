<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { convertToAttributeSlug } from 'dashboard/helper/commons.js';
import { normalizeRegexPattern } from 'shared/helpers/Validators';
import { ATTRIBUTE_MODELS, ATTRIBUTE_TYPES } from './constants';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import NextButton from 'dashboard/components-next/button/Button.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import BusinessManagedToggle from './BusinessManagedToggle.vue';

const props = defineProps({
  onClose: {
    type: Function,
    default: () => {},
  },
  // Passes 0, 1 or 2 (the attribute_model enum) based on the selected tab
  selectedAttributeModelTab: {
    type: Number,
    default: 0,
  },
});

const LIST_TYPE = 6;
const TEXT_TYPE = 0;
const CONTACT_MODEL = 1;

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('getUIFlags');
const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const show = ref(true);
const tagInputTouched = ref(false);
// The modal is created fresh each time it opens, so the tab it opened from is the starting model
const state = reactive({
  displayName: '',
  description: '',
  attributeModel: props.selectedAttributeModelTab || 0,
  attributeType: 0,
  attributeKey: '',
  regexPattern: null,
  regexCue: null,
  regexEnabled: false,
  businessManaged: false,
  values: [],
});

const rules = {
  displayName: { required, minLength: minLength(1) },
  description: { required },
  attributeModel: { required },
  attributeType: { required },
  attributeKey: {
    required,
    isKey: value => !(value.indexOf(' ') >= 0),
  },
};
const v$ = useVuelidate(rules, state);

const models = computed(() => {
  const companiesEnabled = isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.COMPANIES
  );
  return ATTRIBUTE_MODELS.filter(
    item => item.key !== 'COMPANY' || companiesEnabled
  ).map(item => ({
    ...item,
    option: t(`ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.${item.key}`),
  }));
});

const types = computed(() =>
  ATTRIBUTE_TYPES.map(item => ({
    ...item,
    option: t(`ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.${item.key}`),
  }))
);

const isAttributeTypeList = computed(() => state.attributeType === LIST_TYPE);
const isAttributeTypeText = computed(() => state.attributeType === TEXT_TYPE);
const isContactAttribute = computed(
  () => state.attributeModel === CONTACT_MODEL
);
const isTagInputEmpty = computed(
  () => isAttributeTypeList.value && state.values.length === 0
);
const isTagInputInvalid = computed(
  () => tagInputTouched.value && isTagInputEmpty.value
);
const isButtonDisabled = computed(
  () =>
    v$.value.displayName.$invalid ||
    v$.value.description.$invalid ||
    uiFlags.value.isCreating ||
    isTagInputEmpty.value
);
const keyErrorMessage = computed(() =>
  v$.value.attributeKey.isKey.$invalid
    ? t('ATTRIBUTES_MGMT.ADD.FORM.KEY.IN_VALID')
    : t('ATTRIBUTES_MGMT.ADD.FORM.KEY.ERROR')
);

watch(
  () => state.attributeType,
  () => {
    tagInputTouched.value = false;
    state.values = [];
  }
);

const onDisplayNameChange = () => {
  state.attributeKey = convertToAttributeSlug(state.displayName);
};

const addAttributes = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }
  if (!state.regexEnabled) {
    state.regexPattern = null;
    state.regexCue = null;
  }
  let alertMessage;
  try {
    await store.dispatch('attributes/create', {
      attribute_display_name: state.displayName,
      attribute_description: state.description,
      attribute_model: state.attributeModel,
      attribute_display_type: state.attributeType,
      attribute_key: state.attributeKey,
      attribute_values: state.values,
      regex_pattern: normalizeRegexPattern(state.regexPattern),
      regex_cue: state.regexCue,
      business_managed: isContactAttribute.value && state.businessManaged,
    });
    alertMessage = t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE');
    props.onClose();
  } catch (error) {
    alertMessage = error?.message || t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE');
  } finally {
    useAlert(alertMessage);
  }
};
</script>

<template>
  <woot-modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('ATTRIBUTES_MGMT.ADD.TITLE')" />

      <form class="flex w-full" @submit.prevent="addAttributes">
        <div class="w-full">
          <label :class="{ error: v$.attributeModel.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
            <select v-model="state.attributeModel">
              <option v-for="model in models" :key="model.id" :value="model.id">
                {{ model.option }}
              </option>
            </select>
            <span v-if="v$.attributeModel.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.ERROR') }}
            </span>
          </label>
          <woot-input
            v-model="state.displayName"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL')"
            type="text"
            :class="{ error: v$.displayName.$error }"
            :error="
              v$.displayName.$error
                ? $t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR')
                : ''
            "
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            @update:model-value="onDisplayNameChange"
            @blur="v$.displayName.$touch"
          />
          <woot-input
            v-model="state.attributeKey"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL')"
            type="text"
            :class="{ error: v$.attributeKey.$error }"
            :error="v$.attributeKey.$error ? keyErrorMessage : ''"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
            @blur="v$.attributeKey.$touch"
          />
          <label :class="{ error: v$.description.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
            <textarea
              v-model="state.description"
              rows="3"
              type="text"
              :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
              @blur="v$.description.$touch"
            />
            <span v-if="v$.description.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.ERROR') }}
            </span>
          </label>
          <label :class="{ error: v$.attributeType.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
            <select v-model="state.attributeType">
              <option v-for="type in types" :key="type.id" :value="type.id">
                {{ type.option }}
              </option>
            </select>
            <span v-if="v$.attributeType.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.ERROR') }}
            </span>
          </label>
          <div v-if="isAttributeTypeList" class="mb-4">
            <label class="mb-1 block">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.LABEL') }}
            </label>
            <div
              class="rounded-xl border px-3 py-2"
              :class="isTagInputInvalid ? 'border-n-ruby-9' : 'border-n-weak'"
            >
              <TagInput
                v-model="state.values"
                :placeholder="
                  $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.PLACEHOLDER')
                "
                allow-create
                @blur="tagInputTouched = true"
              />
            </div>
            <label
              v-show="isTagInputInvalid"
              class="text-n-ruby-9 dark:text-n-ruby-9 text-sm font-normal mt-1"
            >
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.ERROR') }}
            </label>
          </div>
          <div v-if="isAttributeTypeText">
            <input v-model="state.regexEnabled" type="checkbox" />
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.ENABLE_REGEX.LABEL') }}
          </div>
          <woot-input
            v-if="isAttributeTypeText && state.regexEnabled"
            v-model="state.regexPattern"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.LABEL')"
            type="text"
            :placeholder="
              $t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.PLACEHOLDER')
            "
          />
          <woot-input
            v-if="isAttributeTypeText && state.regexEnabled"
            v-model="state.regexCue"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.LABEL')"
            type="text"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.PLACEHOLDER')"
          />
          <BusinessManagedToggle
            v-if="isContactAttribute"
            v-model="state.businessManaged"
          />
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <NextButton
              faded
              slate
              type="reset"
              :label="$t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT')"
              @click.prevent="onClose"
            />
            <NextButton
              type="submit"
              :label="$t('ATTRIBUTES_MGMT.ADD.SUBMIT')"
              :disabled="isButtonDisabled"
            />
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>
