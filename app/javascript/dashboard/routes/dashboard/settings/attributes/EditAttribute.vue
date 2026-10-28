<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { getRegexp, normalizeRegexPattern } from 'shared/helpers/Validators';
import { ATTRIBUTE_TYPES } from './constants';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import BusinessManagedToggle from './BusinessManagedToggle.vue';

const props = defineProps({
  selectedAttribute: {
    type: Object,
    default: () => {},
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['onClose']);

const LIST_TYPE = 6;
const TEXT_TYPE = 0;

const { t } = useI18n();
const store = useStore();

const tagInputTouched = ref(false);
const state = reactive({
  displayName: '',
  description: '',
  attributeType: 0,
  regexPattern: null,
  regexCue: null,
  regexEnabled: false,
  businessManaged: false,
  attributeKey: '',
  values: [],
});

const rules = {
  displayName: { required },
  attributeType: { required },
  description: { required, minLength: minLength(1) },
  attributeKey: {
    required,
    isKey: value => !(value.indexOf(' ') >= 0),
  },
};
const v$ = useVuelidate(rules, state);

const types = computed(() =>
  ATTRIBUTE_TYPES.map(item => ({
    ...item,
    option: t(`ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.${item.key}`),
  }))
);

const isAttributeTypeList = computed(() => state.attributeType === LIST_TYPE);
const isAttributeTypeText = computed(() => state.attributeType === TEXT_TYPE);
const isContactAttribute = computed(
  () => props.selectedAttribute.attribute_model === 'contact_attribute'
);
const isTagInputEmpty = computed(
  () => isAttributeTypeList.value && state.values.length === 0
);
const isTagInputInvalid = computed(
  () => tagInputTouched.value && isTagInputEmpty.value
);
const isButtonDisabled = computed(
  () => v$.value.description.$invalid || isTagInputEmpty.value
);
const pageTitle = computed(
  () =>
    `${t('ATTRIBUTES_MGMT.EDIT.TITLE')} - ${props.selectedAttribute.attribute_display_name}`
);
const keyErrorMessage = computed(() =>
  v$.value.attributeKey.isKey.$invalid
    ? t('ATTRIBUTES_MGMT.ADD.FORM.KEY.IN_VALID')
    : t('ATTRIBUTES_MGMT.ADD.FORM.KEY.ERROR')
);

const onClose = () => emit('onClose');

const setFormValues = () => {
  const attribute = props.selectedAttribute;
  const regexPattern = attribute.regex_pattern
    ? getRegexp(attribute.regex_pattern).toString()
    : null;
  Object.assign(state, {
    displayName: attribute.attribute_display_name,
    description: attribute.attribute_description,
    attributeType: types.value.find(
      item => item.key.toLowerCase() === attribute.attribute_display_type
    )?.id,
    attributeKey: attribute.attribute_key,
    regexPattern,
    regexCue: attribute.regex_cue,
    regexEnabled: regexPattern != null,
    businessManaged: attribute.business_managed === true,
    values: attribute.attribute_values || [],
  });
};

onMounted(setFormValues);

const editAttributes = async () => {
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
    await store.dispatch('attributes/update', {
      id: props.selectedAttribute.id,
      attribute_description: state.description,
      attribute_display_name: state.displayName,
      attribute_values: state.values,
      regex_pattern: normalizeRegexPattern(state.regexPattern),
      regex_cue: state.regexCue,
      ...(isContactAttribute.value && {
        business_managed: state.businessManaged,
      }),
    });
    alertMessage = t('ATTRIBUTES_MGMT.EDIT.API.SUCCESS_MESSAGE');
    onClose();
  } catch (error) {
    alertMessage =
      error?.message || t('ATTRIBUTES_MGMT.EDIT.API.ERROR_MESSAGE');
  } finally {
    useAlert(alertMessage);
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-col w-full" @submit.prevent="editAttributes">
      <div class="w-full">
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
          @blur="v$.displayName.$touch"
        />
        <woot-input
          v-model="state.attributeKey"
          :label="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL')"
          type="text"
          :class="{ error: v$.attributeKey.$error }"
          :error="v$.attributeKey.$error ? keyErrorMessage : ''"
          :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
          readonly
          @blur="v$.attributeKey.$touch"
        />
        <label :class="{ error: v$.description.$error }">
          {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
          <textarea
            v-model="state.description"
            rows="5"
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
          <select v-model="state.attributeType" disabled>
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
            {{ $t('ATTRIBUTES_MGMT.EDIT.TYPE.LIST.LABEL') }}
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
          :warn-existing-values="!selectedAttribute.business_managed"
        />
      </div>
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
          :label="$t('ATTRIBUTES_MGMT.EDIT.UPDATE_BUTTON_TEXT')"
          :is-loading="isUpdating"
          :disabled="isButtonDisabled"
        />
      </div>
    </form>
  </div>
</template>
