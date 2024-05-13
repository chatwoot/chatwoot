<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.TITLE')"
      :header-content="
        $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.DESCRIPTION')
      "
    />

    <div class="flex flex-col h-auto overflow-auto">
      <div class="flex flex-col px-8 pb-4">
        <woot-tabs
          class="ltr:[&>ul]:pl-0 rtl:[&>ul]:pr-0"
          :index="selectedTabIndex"
          @change="onClickTabChange"
        >
          <woot-tabs-item
            v-for="tab in tabs"
            :key="tab.key"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
      </div>
      <div v-if="selectedTabIndex === 0" class="flex flex-col px-8 pb-4">
        <create-issue
          :account-id="accountId"
          :conversation-id="conversationId"
          @close="onClose"
        />
      </div>

      <div v-else class="flex flex-col px-8 pb-4">
        <link-issue :conversation-id="conversationId" @close="onClose" />
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import LinkIssue from './LinkIssue';
import CreateIssue from './CreateIssue';

import validations from './validations';

export default {
  components: {
    LinkIssue,
    CreateIssue,
  },
  mixins: [alertMixin],
  props: {
    accountId: {
      type: [Number, String],
      required: true,
    },
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  validations,
  computed: {
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('INTEGRATION_SETTINGS.LINEAR.CREATE'),
        },
        {
          key: 1,
          name: this.$t('INTEGRATION_SETTINGS.LINEAR.LINK'),
        },
      ];
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
  },
};
</script>
