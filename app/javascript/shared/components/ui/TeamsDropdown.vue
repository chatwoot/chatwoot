<template>
  <div v-on-clickaway="onCloseDropdownTeam" class="dropdown-wrap">
    <button
      :v-model="assignedTeam"
      class="button-input"
      @click="toggleDropdownTeam"
    >
      <thumbnail
        v-if="
          assignedTeam && assignedTeam.name && assignedTeam && assignedTeam.id
        "
        :src="assignedTeam && assignedTeam.thumbnail"
        size="24px"
        :badge="assignedTeam.channel"
        :username="assignedTeam && assignedTeam.name"
      />
      <div class="name-icon-wrap">
        <div v-if="!assignedTeam" class="name select-agent">
          {{ $t('AGENT_MGMT.SELECTOR.PLACEHOLDER') }}
        </div>
        <div v-else class="name">
          {{ assignedTeam && assignedTeam.name }}
        </div>

        <i v-if="showSearchDropdownTeam" class="icon ion-close-round" />
        <i v-else class="icon ion-chevron-down" />
      </div>
    </button>
    <div
      :class="{ 'dropdown-pane--open': showSearchDropdownTeam }"
      class="dropdown-pane"
    >
      <h4 class="text-block-title">
        {{ $t('AGENT_MGMT.SELECTOR.TITLE.TEAM') }}
      </h4>
      <teams-list
        v-if="showSearchDropdownTeam"
        :options="teamsList"
        :value="assignedTeam"
        @click="onClickTeam"
      />
    </div>
  </div>
</template>

<script>
import teamsList from 'shared/components/ui/TeamsDropdownList.vue';
import { mixin as clickaway } from 'vue-clickaway';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
export default {
  components: {
    teamsList,
    Thumbnail,
  },
  mixins: [clickaway],
  props: {
    teamsList: {
      type: Array,
      default: () => [],
    },
    assignedTeam: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showSearchDropdownTeam: false,
    };
  },
  methods: {
    toggleDropdownTeam() {
      this.showSearchDropdownTeam = !this.showSearchDropdownTeam;
    },
    onCloseDropdownTeam() {
      this.showSearchDropdownTeam = false;
    },
    onClickTeam(label) {
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

  .button-input {
    display: flex;
    width: 100%;
    cursor: pointer;
    justify-content: flex-start;
    background: white;
    font-size: var(--font-size-small);
    cursor: pointer;
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
