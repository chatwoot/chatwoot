<script setup>
import { ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { t } = useI18n();

const enabled = ref(!!props.inbox.drop_assignee_outside_team_on_reopen);

watch(
  () => [props.inbox.id, props.inbox.drop_assignee_outside_team_on_reopen],
  () => {
    enabled.value = !!props.inbox.drop_assignee_outside_team_on_reopen;
  }
);

const handleToggle = async value => {
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      drop_assignee_outside_team_on_reopen: value,
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    enabled.value = !!props.inbox.drop_assignee_outside_team_on_reopen;
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsToggleSection
    v-model="enabled"
    compact
    :header="$t('INBOX_MGMT.ASSIGNMENT.REOPEN_TEAM.TITLE')"
    :description="$t('INBOX_MGMT.ASSIGNMENT.REOPEN_TEAM.DESCRIPTION')"
    @update:model-value="handleToggle"
  />
</template>
