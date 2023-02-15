<template>
  <div v-on-clickaway="onClose" class="bulk-action__teams">
    <div class="triangle" :style="cssVars">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path
          d="M20 12l-8-8-12 12"
          fill="var(--white)"
          fill-rule="evenodd"
          stroke="var(--s-50)"
          stroke-width="1px"
        />
      </svg>
    </div>
    <div class="header flex-between">
      <span>{{ $t('BULK_ACTION.TEAMS.TEAM_SELECT_LABEL') }}</span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="container">
      <div class="team__list-container">
        <ul>
          <li class="search-container">
            <div class="agent-list-search flex-between">
              <fluent-icon icon="search" class="search-icon" size="16" />
              <input
                ref="search"
                v-model="query"
                type="search"
                placeholder="Search"
                class="agent--search_input"
              />
            </div>
          </li>
          <template v-if="filteredTeams.length">
            <li v-for="team in filteredTeams" :key="team.id">
              <div class="team__list-item" @click="assignTeam(team)">
                <span class="reports-option__title">{{ team.name }}</span>
              </div>
            </li>
          </template>
          <li v-else>
            <div class="team__list-item">
              <span class="reports-option__title">{{
                $t('BULK_ACTION.TEAMS.NO_TEAMS_AVAILABLE')
              }}</span>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import bulkActionsMixin from 'dashboard/mixins/bulkActionsMixin.js';
export default {
  mixins: [clickaway, bulkActionsMixin],
  data() {
    return {
      query: '',
      selectedteams: [],
    };
  },
  computed: {
    ...mapGetters({ teams: 'teams/getTeams' }),
    filteredTeams() {
      return [
        { name: 'None', id: 0 },
        ...this.teams.filter(team =>
          team.name.toLowerCase().includes(this.query.toLowerCase())
        ),
      ];
    },
  },
  methods: {
    assignTeam(key) {
      this.$emit('assign-team', key);
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.bulk-action__teams {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--s-50);
  box-shadow: var(--shadow-dropdown-pane);
  max-width: 75%;
  position: absolute;
  right: var(--space-small);
  top: var(--space-larger);
  transform-origin: top right;
  width: auto;
  z-index: var(--z-index-twenty);
  min-width: var(--space-giga);
  .header {
    padding: var(--space-one);

    span {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
    }
  }

  .container {
    max-height: var(--space-giga);
    overflow-y: auto;
    .team__list-container {
      height: 100%;
    }
    .agent-list-search {
      padding: 0 var(--space-one);
      border: 1px solid var(--s-100);
      border-radius: var(--border-radius-medium);
      background-color: var(--s-50);
      .search-icon {
        color: var(--s-400);
      }

      .agent--search_input {
        border: 0;
        font-size: var(--font-size-mini);
        margin: 0;
        background-color: transparent;
        height: unset;
      }
    }
  }
  .triangle {
    display: block;
    z-index: var(--z-index-one);
    position: absolute;
    top: calc(var(--space-slab) * -1);
    right: var(--triangle-position);
    text-align: left;
  }
}
ul {
  margin: 0;
  list-style: none;
}

.team__list-item {
  display: flex;
  align-items: center;
  padding: var(--space-one);
  cursor: pointer;
  &:hover {
    background-color: var(--s-50);
  }
  span {
    font-size: var(--font-size-small);
  }
}

.search-container {
  padding: 0 var(--space-one);
  position: sticky;
  top: 0;
  z-index: var(--z-index-twenty);
  background-color: var(--white);
}
</style>
