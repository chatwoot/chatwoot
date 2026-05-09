<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import notionClient from 'dashboard/api/notion_auth.js';
import notionAPI from 'dashboard/api/integrations/notion';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Integration from './Integration.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();
const store = useStore();
const integrationLoaded = ref(false);
const isLoadingIssueTracker = ref(false);
const isValidatingIssueTracker = ref(false);
const isSavingIssueTracker = ref(false);
const validatedDataSourceId = ref('');
const issueTrackerErrors = ref({
  data_source_id: '',
  title_property: '',
});
const issueTrackerForm = ref({
  data_source_id: '',
  title_property: '',
  description_property: '',
  assignee_property: '',
  project_property: '',
  status_property: '',
  priority_property: '',
  label_property: '',
});

const optionalPropertyFields = computed(() => [
  {
    key: 'description_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.DESCRIPTION_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.DESCRIPTION_PROPERTY.PLACEHOLDER'
    ),
  },
  {
    key: 'assignee_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.ASSIGNEE_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.ASSIGNEE_PROPERTY.PLACEHOLDER'
    ),
  },
  {
    key: 'project_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.PROJECT_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.PROJECT_PROPERTY.PLACEHOLDER'
    ),
  },
  {
    key: 'status_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.STATUS_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.STATUS_PROPERTY.PLACEHOLDER'
    ),
  },
  {
    key: 'priority_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.PRIORITY_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.PRIORITY_PROPERTY.PLACEHOLDER'
    ),
  },
  {
    key: 'label_property',
    label: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.LABEL_PROPERTY.LABEL'
    ),
    placeholder: t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.LABEL_PROPERTY.PLACEHOLDER'
    ),
  },
]);

const integration = useFunctionGetter('integrations/getIntegration', 'notion');

const uiFlags = useMapGetter('integrations/getUIFlags');

const isIntegrationEnabled = computed(() => Boolean(integration.value.enabled));

const integrationAction = computed(() => {
  if (isIntegrationEnabled.value) {
    return 'disconnect';
  }

  return '';
});

const isSettingsLoading = computed(
  () =>
    !integrationLoaded.value ||
    isLoadingIssueTracker.value ||
    uiFlags.value.isCreatingNotion
);

const authorize = async () => {
  const response = await notionClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};

const getResponseErrorMessage = error => {
  const responseError = error.response?.data?.error;

  if (typeof responseError === 'string') {
    return responseError;
  }

  return responseError?.message || '';
};

const clearIssueTrackerErrors = () => {
  issueTrackerErrors.value = {
    data_source_id: '',
    title_property: '',
  };
};

const applyIssueTrackerSettings = settings => {
  Object.keys(issueTrackerForm.value).forEach(key => {
    issueTrackerForm.value[key] = settings[key] || '';
  });
  validatedDataSourceId.value = issueTrackerForm.value.data_source_id;
};

const fetchIssueTrackerSettings = async () => {
  if (!isIntegrationEnabled.value) {
    return;
  }

  try {
    isLoadingIssueTracker.value = true;
    const { data } = await notionAPI.getIssueTracker();
    applyIssueTrackerSettings(data);
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.LOAD_ERROR'));
  } finally {
    isLoadingIssueTracker.value = false;
  }
};

const initializeNotionIntegration = async () => {
  await store.dispatch('integrations/get', 'notion');
  integrationLoaded.value = true;
  await fetchIssueTrackerSettings();
};

const handleDataSourceInput = () => {
  issueTrackerErrors.value.data_source_id = '';

  if (
    issueTrackerForm.value.data_source_id.trim() !== validatedDataSourceId.value
  ) {
    issueTrackerForm.value.title_property = '';
  }
};

const validateDataSource = async () => {
  clearIssueTrackerErrors();
  const dataSourceId = issueTrackerForm.value.data_source_id.trim();

  if (!dataSourceId) {
    issueTrackerErrors.value.data_source_id = t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.DATA_SOURCE_REQUIRED'
    );
    return;
  }

  try {
    isValidatingIssueTracker.value = true;
    const { data } = await notionAPI.validateIssueTracker({
      data_source_id: dataSourceId,
    });
    issueTrackerForm.value.data_source_id = data.data_source_id;
    issueTrackerForm.value.title_property = data.title_property;
    validatedDataSourceId.value = data.data_source_id;
    useAlert(t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.VALIDATE_SUCCESS'));
  } catch (error) {
    issueTrackerErrors.value.data_source_id =
      getResponseErrorMessage(error) ||
      t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.VALIDATE_ERROR');
  } finally {
    isValidatingIssueTracker.value = false;
  }
};

const validateIssueTrackerForm = () => {
  clearIssueTrackerErrors();
  const dataSourceId = issueTrackerForm.value.data_source_id.trim();
  const titleProperty = issueTrackerForm.value.title_property.trim();

  if (!dataSourceId) {
    issueTrackerErrors.value.data_source_id = t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.DATA_SOURCE_REQUIRED'
    );
  }

  if (!titleProperty) {
    issueTrackerErrors.value.title_property = t(
      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.TITLE_REQUIRED'
    );
  }

  return dataSourceId && titleProperty;
};

const buildIssueTrackerPayload = () => {
  const payload = {
    data_source_id: issueTrackerForm.value.data_source_id.trim(),
    title_property: issueTrackerForm.value.title_property.trim(),
  };

  optionalPropertyFields.value.forEach(({ key }) => {
    const value = issueTrackerForm.value[key].trim();

    if (value) {
      payload[key] = value;
    }
  });

  return payload;
};

const saveIssueTrackerSettings = async () => {
  if (!validateIssueTrackerForm()) {
    return;
  }

  try {
    isSavingIssueTracker.value = true;
    const { data } = await notionAPI.updateIssueTracker(
      buildIssueTrackerPayload()
    );
    applyIssueTrackerSettings(data);
    useAlert(t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.SAVE_ERROR'));
  } finally {
    isSavingIssueTracker.value = false;
  }
};

onMounted(() => {
  initializeNotionIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="isSettingsLoading">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.NOTION.HEADER')"
        description=""
        feature-name="notion_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          :integration-id="integration.id"
          :integration-logo="integration.logo"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="integration.enabled"
          :integration-action="integrationAction"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.NOTION.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.NOTION.DELETE.MESSAGE'),
          }"
        >
          <template #action>
            <Button
              faded
              blue
              type="button"
              :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
              @click="authorize"
            />
          </template>
        </Integration>

        <div
          v-if="isIntegrationEnabled"
          class="p-6 outline outline-n-container outline-1 bg-n-card rounded-xl"
        >
          <div class="flex flex-col gap-5">
            <div>
              <h3 class="mb-1 text-heading-1 text-n-slate-12">
                {{ t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.TITLE') }}
              </h3>
              <p class="mb-0 text-body-main text-n-slate-11">
                {{ t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.DESCRIPTION') }}
              </p>
            </div>

            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div class="md:col-span-2">
                <Input
                  v-model="issueTrackerForm.data_source_id"
                  :label="
                    t(
                      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.DATA_SOURCE_ID.LABEL'
                    )
                  "
                  :placeholder="
                    t(
                      'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.DATA_SOURCE_ID.PLACEHOLDER'
                    )
                  "
                  :message="issueTrackerErrors.data_source_id"
                  :message-type="
                    issueTrackerErrors.data_source_id ? 'error' : 'info'
                  "
                  :disabled="isValidatingIssueTracker || isSavingIssueTracker"
                  @input="handleDataSourceInput"
                />
              </div>

              <Input
                v-model="issueTrackerForm.title_property"
                :label="
                  t(
                    'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.TITLE_PROPERTY.LABEL'
                  )
                "
                :placeholder="
                  t(
                    'INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.FIELDS.TITLE_PROPERTY.PLACEHOLDER'
                  )
                "
                :message="issueTrackerErrors.title_property"
                :message-type="
                  issueTrackerErrors.title_property ? 'error' : 'info'
                "
                disabled
              />

              <Input
                v-for="field in optionalPropertyFields"
                :key="field.key"
                v-model="issueTrackerForm[field.key]"
                :label="field.label"
                :placeholder="field.placeholder"
                :disabled="isValidatingIssueTracker || isSavingIssueTracker"
              />
            </div>

            <div class="flex flex-col justify-end gap-3 sm:flex-row">
              <Button
                faded
                slate
                type="button"
                :label="t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.VALIDATE')"
                :is-loading="isValidatingIssueTracker"
                :disabled="isValidatingIssueTracker || isSavingIssueTracker"
                @click="validateDataSource"
              />
              <Button
                blue
                type="button"
                :label="t('INTEGRATION_SETTINGS.NOTION.ISSUE_TRACKER.SAVE')"
                :is-loading="isSavingIssueTracker"
                :disabled="isValidatingIssueTracker || isSavingIssueTracker"
                @click="saveIssueTrackerSettings"
              />
            </div>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
