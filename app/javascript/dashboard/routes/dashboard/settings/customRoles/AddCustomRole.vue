<script setup>
import { ref, reactive, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const AVAILABLE_CUSTOM_ROLE_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
  'contact_manage',
  'report_manage',
  'knowledge_base_manage',
];

const name = ref('');
const description = ref('');
const selectedPermissions = ref([]);
const addCustomRole = reactive({
  showLoading: false,
  message: '',
});

const rules = computed(() => ({
  name: { required, minLength: minLength(2) },
  description: { required },
  selectedPermissions: { required, minLength: minLength(1) },
}));

const v$ = useVuelidate(rules, { name, description, selectedPermissions });

const resetForm = () => {
  name.value = '';
  description.value = '';
  selectedPermissions.value = [];
  v$.value.$reset();
};

const addCustomRoleResponse = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  addCustomRole.showLoading = true;
  try {
    await store.dispatch('createCustomRole', {
      name: name.value,
      description: description.value,
      permissions: selectedPermissions.value,
    });
    useAlert(t('CUSTOM_ROLE.ADD.API.SUCCESS_MESSAGE'));
    resetForm();
    emit('close');
  } catch (error) {
    const errorMessage =
      error?.message || t('CUSTOM_ROLE.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    addCustomRole.showLoading = false;
  }
};

const isSubmitDisabled = computed(
  () => v$.value.$invalid || addCustomRole.showLoading
);
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('CUSTOM_ROLE.ADD.TITLE')"
      :header-content="$t('CUSTOM_ROLE.ADD.DESC')"
    />
    <form class="flex flex-col w-full" @submit.prevent="addCustomRoleResponse">
      <div class="w-full">
        <label :class="{ 'text-red-500': v$.name.$error }">
          {{ $t('CUSTOM_ROLE.ADD.FORM.NAME.LABEL') }}
          <input
            v-model.trim="name"
            type="text"
            :class="{ '!border-red-500': v$.name.$error }"
            :placeholder="$t('CUSTOM_ROLE.ADD.FORM.NAME.PLACEHOLDER')"
            @blur="v$.name.$touch"
          />
        </label>
      </div>

      <div class="w-full">
        <label :class="{ 'text-red-500': v$.description.$error }">
          {{ $t('CUSTOM_ROLE.ADD.FORM.DESCRIPTION.LABEL') }}
        </label>
        <div class="editor-wrap">
          <WootMessageEditor
            v-model="description"
            class="message-editor [&>div]:px-1"
            :class="{ editor_warning: v$.description.$error }"
            enable-variables
            :enable-canned-responses="false"
            :placeholder="$t('CUSTOM_ROLE.ADD.FORM.DESCRIPTION.PLACEHOLDER')"
            @blur="v$.description.$touch"
          />
        </div>
      </div>

      <div class="w-full">
        <label :class="{ 'text-red-500': v$.selectedPermissions.$error }">
          {{ $t('CUSTOM_ROLE.ADD.FORM.PERMISSIONS.LABEL') }}
        </label>
        <div class="flex flex-col gap-2.5 mb-4">
          <div
            v-for="permission in AVAILABLE_CUSTOM_ROLE_PERMISSIONS"
            :key="permission"
            class="flex items-center"
          >
            <input
              :id="permission"
              v-model="selectedPermissions"
              type="checkbox"
              :value="permission"
              name="permissions"
              class="ltr:mr-2 rtl:ml-2"
            />
            <label :for="permission" class="text-sm">
              {{
                `${$t(
                  `CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`
                )} (${permission})`
              }}
            </label>
          </div>
        </div>
      </div>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <WootSubmitButton
          :disabled="isSubmitDisabled"
          :button-text="$t('CUSTOM_ROLE.ADD.FORM.SUBMIT')"
          :loading="addCustomRole.showLoading"
        />
        <button class="button clear" @click.prevent="emit('close')">
          {{ $t('CUSTOM_ROLE.ADD.CANCEL_BUTTON_TEXT') }}
        </button>
      </div>
    </form>
  </div>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>
