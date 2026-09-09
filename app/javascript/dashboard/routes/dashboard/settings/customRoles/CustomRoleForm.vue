<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import {
  MANAGE_ALL_CONVERSATION_PERMISSIONS,
  CONVERSATION_UNASSIGNED_PERMISSIONS,
  CONVERSATION_PARTICIPATING_PERMISSIONS,
  CONTACT_PERMISSIONS,
  CONTACT_INBOX_PERMISSIONS,
  REPORTS_PERMISSIONS,
  REPORT_PAGE_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import {
  CONVERSATION_PERMISSION_OPTIONS,
  CONTACT_SCOPE_OPTIONS,
  CONTACT_ACTION_PERMISSIONS,
  REPORT_PERMISSION_OPTIONS,
} from './customRolePermissions';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const records = useMapGetter('customRole/getCustomRoles');
const uiFlags = useMapGetter('customRole/getUIFlags');

const name = ref('');
const description = ref('');
const selectedPermissions = ref([]);
const isLoadingRole = ref(false);

const isEdit = computed(() => route.name === 'custom_roles_edit');
const roleId = computed(() => Number(route.params.roleId));

const rules = computed(() => ({
  name: { required, minLength: minLength(2) },
  description: { required },
  selectedPermissions: { required, minLength: minLength(1) },
}));

const v$ = useVuelidate(rules, { name, description, selectedPermissions });

const pageTitle = computed(() =>
  t(isEdit.value ? 'CUSTOM_ROLE.EDIT.TITLE' : 'CUSTOM_ROLE.ADD.TITLE')
);
const pageDescription = computed(() =>
  t(isEdit.value ? 'CUSTOM_ROLE.EDIT.DESC' : 'CUSTOM_ROLE.ADD.DESC')
);
const submitButtonText = computed(() =>
  t(isEdit.value ? 'CUSTOM_ROLE.EDIT.SUBMIT' : 'CUSTOM_ROLE.ADD.SUBMIT')
);

const isSubmitting = computed(
  () => uiFlags.value.creatingItem || uiFlags.value.updatingItem
);

const contactScope = computed({
  get() {
    if (selectedPermissions.value.includes(CONTACT_PERMISSIONS)) {
      return CONTACT_PERMISSIONS;
    }
    if (selectedPermissions.value.includes(CONTACT_INBOX_PERMISSIONS)) {
      return CONTACT_INBOX_PERMISSIONS;
    }
    return '';
  },
  set(value) {
    selectedPermissions.value = selectedPermissions.value.filter(
      permission => !CONTACT_SCOPE_OPTIONS.includes(permission)
    );
    if (value) {
      selectedPermissions.value = [...selectedPermissions.value, value];
    }
  },
});

const hasContactAccess = computed(() => Boolean(contactScope.value));

const allReportPagesSelected = computed(() =>
  REPORT_PERMISSION_OPTIONS.every(permission =>
    selectedPermissions.value.includes(permission)
  )
);

const someReportPagesSelected = computed(
  () =>
    REPORT_PERMISSION_OPTIONS.some(permission =>
      selectedPermissions.value.includes(permission)
    ) && !allReportPagesSelected.value
);

const hasAllReports = computed({
  get() {
    return (
      selectedPermissions.value.includes(REPORTS_PERMISSIONS) ||
      allReportPagesSelected.value
    );
  },
  set(enabled) {
    selectedPermissions.value = selectedPermissions.value.filter(
      permission =>
        permission !== REPORTS_PERMISSIONS &&
        !REPORT_PAGE_PERMISSIONS.includes(permission)
    );
    if (enabled) {
      selectedPermissions.value = [
        ...selectedPermissions.value,
        REPORTS_PERMISSIONS,
        ...REPORT_PAGE_PERMISSIONS,
      ];
    }
  },
});

const isPermissionSelected = permission =>
  selectedPermissions.value.includes(permission);

const togglePermission = (permission, enabled) => {
  if (enabled) {
    if (!selectedPermissions.value.includes(permission)) {
      selectedPermissions.value = [...selectedPermissions.value, permission];
    }
    return;
  }

  selectedPermissions.value = selectedPermissions.value.filter(
    item => item !== permission
  );
};

watch(selectedPermissions, (newValue, oldValue = []) => {
  let nextPermissions = [...newValue];

  const hasAddedManageAll =
    newValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS) &&
    !oldValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS);
  const hasRemovedManageAll =
    oldValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS) &&
    !newValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS);

  if (hasAddedManageAll) {
    nextPermissions = [
      ...new Set([
        ...nextPermissions,
        CONVERSATION_UNASSIGNED_PERMISSIONS,
        CONVERSATION_PARTICIPATING_PERMISSIONS,
      ]),
    ];
  } else if (hasRemovedManageAll) {
    nextPermissions = nextPermissions.filter(
      permission => permission !== MANAGE_ALL_CONVERSATION_PERMISSIONS
    );
  }

  const hasContactScope = CONTACT_SCOPE_OPTIONS.some(permission =>
    nextPermissions.includes(permission)
  );
  if (
    !hasContactScope &&
    CONTACT_ACTION_PERMISSIONS.some(permission =>
      nextPermissions.includes(permission)
    )
  ) {
    nextPermissions = nextPermissions.filter(
      permission => !CONTACT_ACTION_PERMISSIONS.includes(permission)
    );
  }

  const hasEveryReportPage = REPORT_PERMISSION_OPTIONS.every(permission =>
    nextPermissions.includes(permission)
  );
  const hasReportManage = nextPermissions.includes(REPORTS_PERMISSIONS);

  if (hasEveryReportPage && !hasReportManage) {
    nextPermissions = [...nextPermissions, REPORTS_PERMISSIONS];
  } else if (!hasEveryReportPage && hasReportManage) {
    nextPermissions = nextPermissions.filter(
      permission => permission !== REPORTS_PERMISSIONS
    );
  }

  const unchanged =
    nextPermissions.length === newValue.length &&
    nextPermissions.every(permission => newValue.includes(permission));
  if (!unchanged) {
    selectedPermissions.value = nextPermissions;
  }
});

const populateForm = role => {
  name.value = role.name || '';
  description.value = role.description || '';
  const permissions = [...(role.permissions || [])];

  if (
    permissions.includes(REPORTS_PERMISSIONS) &&
    !REPORT_PERMISSION_OPTIONS.every(permission =>
      permissions.includes(permission)
    )
  ) {
    permissions.push(
      ...REPORT_PERMISSION_OPTIONS.filter(
        permission => !permissions.includes(permission)
      )
    );
  }

  selectedPermissions.value = permissions;
  v$.value.$reset();
};

const goToList = () => {
  router.push({ name: 'custom_roles_list' });
};

const loadRole = async () => {
  if (!isEdit.value) return;

  isLoadingRole.value = true;
  try {
    if (!records.value.length) {
      await store.dispatch('customRole/getCustomRole');
    }
    const role = records.value.find(item => item.id === roleId.value);
    if (!role) {
      useAlert(t('CUSTOM_ROLE.EDIT.API.NOT_FOUND'));
      goToList();
      return;
    }
    populateForm(role);
  } finally {
    isLoadingRole.value = false;
  }
};

onMounted(() => {
  loadRole();
});

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const roleData = {
    name: name.value,
    description: description.value,
    permissions: [...new Set(selectedPermissions.value)],
  };

  try {
    if (isEdit.value) {
      await store.dispatch('customRole/updateCustomRole', {
        id: roleId.value,
        ...roleData,
      });
      useAlert(t('CUSTOM_ROLE.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('customRole/createCustomRole', roleData);
      useAlert(t('CUSTOM_ROLE.ADD.API.SUCCESS_MESSAGE'));
    }
    goToList();
  } catch (error) {
    useAlert(error?.message || t('CUSTOM_ROLE.FORM.API.ERROR_MESSAGE'));
  }
};

const isSubmitDisabled = computed(
  () => v$.value.$invalid || isSubmitting.value || isLoadingRole.value
);
</script>

<template>
  <div class="flex flex-col w-full gap-6 pb-8">
    <BaseSettingsHeader
      :title="pageTitle"
      :description="pageDescription"
      :back-button-label="$t('CUSTOM_ROLE.FORM.BACK_BUTTON_TEXT')"
    />

    <form
      class="flex flex-col w-full max-w-3xl gap-6"
      @submit.prevent="handleSubmit"
    >
      <div class="flex flex-col gap-4 p-5 rounded-xl bg-n-solid-2">
        <Input
          v-model="name"
          :label="$t('CUSTOM_ROLE.FORM.NAME.LABEL')"
          :placeholder="$t('CUSTOM_ROLE.FORM.NAME.PLACEHOLDER')"
          :message="v$.name.$error ? $t('CUSTOM_ROLE.FORM.NAME.ERROR') : ''"
          :message-type="v$.name.$error ? 'error' : 'info'"
          autofocus
          @blur="v$.name.$touch"
        />
        <TextArea
          v-model="description"
          :label="$t('CUSTOM_ROLE.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('CUSTOM_ROLE.FORM.DESCRIPTION.PLACEHOLDER')"
          :max-length="500"
          :message="
            v$.description.$error
              ? $t('CUSTOM_ROLE.FORM.DESCRIPTION.ERROR')
              : ''
          "
          :message-type="v$.description.$error ? 'error' : 'info'"
          @blur="v$.description.$touch"
        />
      </div>

      <div
        class="flex flex-col gap-5 p-5 rounded-xl bg-n-solid-2"
        :class="{
          'outline outline-1 outline-n-ruby-8': v$.selectedPermissions.$error,
        }"
      >
        <div>
          <h2 class="text-base font-medium text-n-slate-12">
            {{ $t('CUSTOM_ROLE.FORM.PERMISSIONS.LABEL') }}
          </h2>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ $t('CUSTOM_ROLE.FORM.PERMISSIONS.DESC') }}
          </p>
        </div>

        <section class="flex flex-col gap-3">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CUSTOM_ROLE.FORM.GROUPS.CONVERSATIONS') }}
          </h3>
          <label
            v-for="permission in CONVERSATION_PERMISSION_OPTIONS"
            :key="permission"
            class="flex items-start gap-2.5"
          >
            <Checkbox
              :model-value="isPermissionSelected(permission)"
              @update:model-value="
                enabled => togglePermission(permission, enabled)
              "
            />
            <span class="text-sm text-n-slate-12">
              {{ $t(`CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`) }}
            </span>
          </label>
        </section>

        <section class="flex flex-col gap-3">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CUSTOM_ROLE.FORM.GROUPS.CONTACTS') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ $t('CUSTOM_ROLE.FORM.CONTACTS.SCOPE_HINT') }}
          </p>
          <label class="flex items-start gap-2.5">
            <input
              v-model="contactScope"
              type="radio"
              value=""
              name="contact-scope"
              class="mt-0.5"
            />
            <span class="flex flex-col">
              <span class="text-sm text-n-slate-12">
                {{ $t('CUSTOM_ROLE.FORM.CONTACTS.NO_ACCESS') }}
              </span>
              <span class="text-xs text-n-slate-11">
                {{ $t('CUSTOM_ROLE.FORM.CONTACTS.NO_ACCESS_HELP') }}
              </span>
            </span>
          </label>
          <label
            v-for="permission in CONTACT_SCOPE_OPTIONS"
            :key="permission"
            class="flex items-start gap-2.5"
          >
            <input
              v-model="contactScope"
              type="radio"
              :value="permission"
              name="contact-scope"
              class="mt-0.5"
            />
            <span class="flex flex-col">
              <span class="text-sm text-n-slate-12">
                {{ $t(`CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`) }}
              </span>
              <span class="text-xs text-n-slate-11">
                {{
                  $t(
                    `CUSTOM_ROLE.FORM.CONTACTS.SCOPE_HELP.${permission.toUpperCase()}`
                  )
                }}
              </span>
            </span>
          </label>
          <label
            v-for="permission in CONTACT_ACTION_PERMISSIONS"
            :key="permission"
            class="flex items-start gap-2.5"
            :class="{ 'opacity-50': !hasContactAccess }"
          >
            <Checkbox
              :model-value="isPermissionSelected(permission)"
              :disabled="!hasContactAccess"
              @update:model-value="
                enabled => togglePermission(permission, enabled)
              "
            />
            <span class="text-sm text-n-slate-12">
              {{ $t(`CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`) }}
            </span>
          </label>
        </section>

        <section class="flex flex-col gap-3">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CUSTOM_ROLE.FORM.GROUPS.REPORTS') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ $t('CUSTOM_ROLE.FORM.REPORTS.HINT') }}
          </p>
          <label class="flex items-start gap-2.5">
            <Checkbox
              v-model="hasAllReports"
              :indeterminate="someReportPagesSelected"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('CUSTOM_ROLE.PERMISSIONS.REPORT_MANAGE') }}
            </span>
          </label>
          <div class="flex flex-col gap-2.5 ltr:pl-6 rtl:pr-6">
            <label
              v-for="permission in REPORT_PERMISSION_OPTIONS"
              :key="permission"
              class="flex items-start gap-2.5"
            >
              <Checkbox
                :model-value="isPermissionSelected(permission)"
                @update:model-value="
                  enabled => togglePermission(permission, enabled)
                "
              />
              <span class="text-sm text-n-slate-12">
                {{ $t(`CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`) }}
              </span>
            </label>
          </div>
        </section>

        <section class="flex flex-col gap-3">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CUSTOM_ROLE.FORM.GROUPS.KNOWLEDGE_BASE') }}
          </h3>
          <label class="flex items-start gap-2.5">
            <Checkbox
              :model-value="isPermissionSelected('knowledge_base_manage')"
              @update:model-value="
                enabled => togglePermission('knowledge_base_manage', enabled)
              "
            />
            <span class="text-sm text-n-slate-12">
              {{ $t('CUSTOM_ROLE.PERMISSIONS.KNOWLEDGE_BASE_MANAGE') }}
            </span>
          </label>
        </section>
      </div>

      <div class="flex flex-row justify-end w-full gap-2">
        <Button
          faded
          slate
          type="button"
          :label="$t('CUSTOM_ROLE.FORM.CANCEL_BUTTON_TEXT')"
          @click="goToList"
        />
        <Button
          type="submit"
          :label="submitButtonText"
          :disabled="isSubmitDisabled"
          :is-loading="isSubmitting"
        />
      </div>
    </form>
  </div>
</template>
