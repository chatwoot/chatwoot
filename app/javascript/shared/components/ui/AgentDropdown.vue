<template>
  <div v-on-clickaway="onCloseDropdownAgent" class="dropdown-wrap">
    <button
      :v-model="assignedAgent"
      class="button-input"
      @click="toggleDropdownAgent"
    >
      <thumbnail
        v-if="
          assignedAgent &&
            assignedAgent.name &&
            assignedAgent &&
            assignedAgent.id
        "
        :src="assignedAgent && assignedAgent.thumbnail"
        size="24px"
        :status="assignedAgent && assignedAgent.availability_status"
        :badge="assignedAgent && assignedAgent.channel"
        :username="assignedAgent && assignedAgent.name"
      />
      <div class="name-icon-wrap">
        <div v-if="!assignedAgent" class="name select-agent">
          {{ $t('AGENT_MGMT.SELECTOR.PLACEHOLDER') }}
        </div>
        <div v-else class="name">
          {{ assignedAgent && assignedAgent.name }}
        </div>
        <i v-if="showSearchDropdownAgent" class="icon ion-close-round" />
        <i v-else class="icon ion-chevron-down" />
      </div>
    </button>
    <div
      :class="{ 'dropdown-pane--open': showSearchDropdownAgent }"
      class="dropdown-pane"
    >
      <h4 class="text-block-title">
        {{ $t('AGENT_MGMT.SELECTOR.TITLE.AGENT') }}
      </h4>
      <agents-list
        v-if="showSearchDropdownAgent"
        :options="agentsList"
        :value="assignedAgent"
        @click="ShowAgent"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import agentsList from 'shared/components/ui/AgentDropdownList.vue';
import { mixin as clickaway } from 'vue-clickaway';
export default {
  components: {
    Thumbnail,
    agentsList,
  },
  mixins: [clickaway],
  props: {
    agentsList: {
      type: Array,
      default: () => [],
    },
    assignedAgent: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showSearchDropdownAgent: false,
    };
  },
  methods: {
    toggleDropdownAgent() {
      this.showSearchDropdownAgent = !this.showSearchDropdownAgent;
    },
    onCloseDropdownAgent() {
      this.showSearchDropdownAgent = false;
    },
    ShowAgent(label) {
      this.$emit('click', label);
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-wrap {
  display: flex;
  position: relative;
  width: 100%;
  margin-right: var(--space-one);
  margin-bottom: var(--space-small);

  .button-input {
    display: flex;
    width: 100%;
    cursor: pointer;
    justify-content: flex-start;
    background: white;
    font-size: var(--font-size-small);
    border: 1px solid lightgray;
    border-radius: var(--border-radius-normal);
    padding: 0.6rem;
  }

  &::v-deep .user-thumbnail-box {
    margin-right: var(--space-one);
  }

  .name-icon-wrap {
    display: flex;
    justify-content: space-between;
    width: 100%;
    padding: var(--space-smaller) 0;
    line-height: var(--space-normal);
    min-width: 0;

    .select-agent {
      color: var(--b-600);
    }

    .name {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin-right: var(--space-small);
    }
  }

  .dropdown-pane {
    box-sizing: border-box;
    top: 4rem;
    right: 0;
    position: absolute;
    width: 100%;

    &::v-deep {
      .dropdown-menu__item .button {
        width: 100%;
        text-overflow: ellipsis;
        overflow: hidden;
        white-space: nowrap;
        padding: var(--space-smaller) var(--space-small);

        .name-icon-wrap {
          width: 100%;
        }

        .name {
          width: 100%;
        }
      }
    }
  }
}
</style>
