<template>
  <div v-on-clickaway="onClose" class="bulk-action__teams">
    <div class="triangle">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path d="M20 12l-8-8-12 12" fill-rule="evenodd" stroke-width="1px" />
      </svg>
    </div>
    <div class="header flex items-center justify-between">
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
            <div
              class="agent-list-search h-8 flex justify-between items-center gap-2"
            >
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
                <span
                  class="my-0 ltr:ml-2 rtl:mr-2 text-slate-800 dark:text-slate-75"
                >
                  {{ team.name }}
                </span>
              </div>
            </li>
          </template>
          <li v-else>
            <div class="team__list-item">
              <span
                class="my-0 ltr:ml-2 rtl:mr-2 text-slate-800 dark:text-slate-75"
              >
                {{ $t('BULK_ACTION.TEAMS.NO_TEAMS_AVAILABLE') }}
              </span>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
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
  @apply max-w-[75%] absolute right-2 top-12 origin-top-right w-auto z-20 min-w-[15rem] bg-white dark:bg-slate-800 rounded-lg border border-solid border-slate-50 dark:border-slate-700 shadow-md;
  .header {
    @apply p-2.5;

    span {
      @apply text-sm font-medium;
    }
  }

  .container {
    @apply overflow-y-auto max-h-[15rem];
    .team__list-container {
      @apply h-full;
    }
    .agent-list-search {
      @apply py-0 px-2.5 bg-slate-50 dark:bg-slate-900 border border-solid border-slate-100 dark:border-slate-600/70 rounded-md;
      .search-icon {
        @apply text-slate-400 dark:text-slate-200;
      }

      .agent--search_input {
        @apply border-0 text-xs m-0 dark:bg-transparent bg-transparent w-full h-[unset];
      }
    }
  }
  .triangle {
    right: var(--triangle-position);
    @apply block z-10 absolute text-left -top-3;

    svg path {
      @apply fill-white dark:fill-slate-800 stroke-slate-50 dark:stroke-slate-600/50;
    }
  }
}
ul {
  @apply m-0 list-none;

  li {
    &:last-child {
      .agent-list-item {
        @apply last:rounded-b-lg;
      }
    }
  }
}

.team__list-item {
  @apply flex items-center p-2.5 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-900;
  span {
    @apply text-sm;
  }
}

.search-container {
  @apply py-0 px-2.5 sticky top-0 z-20 bg-white dark:bg-slate-800;
}
</style>
