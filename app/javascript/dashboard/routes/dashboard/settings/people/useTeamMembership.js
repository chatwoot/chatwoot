import { computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';

/**
 * Team membership read from both directions, so the agent list can name an
 * agent's teams and the team list can show who is in it.
 *
 * Members are fetched one request per team: the teams endpoint carries no
 * membership, and accounts run a handful of teams rather than hundreds. If that
 * stops being true, this is the place that needs a batched endpoint.
 */
export function useTeamMembership() {
  const store = useStore();
  const teams = useMapGetter('teams/getTeams');
  const teamMembersFor = useMapGetter('teamMembers/getTeamMembers');

  onMounted(async () => {
    await store.dispatch('teams/get');
    await Promise.all(
      teams.value.map(team =>
        store.dispatch('teamMembers/get', { teamId: team.id })
      )
    );
  });

  const membersByTeamId = computed(() =>
    teams.value.reduce((acc, team) => {
      acc[team.id] = teamMembersFor.value(team.id) ?? [];
      return acc;
    }, {})
  );

  const teamsByAgentId = computed(() =>
    teams.value.reduce((acc, team) => {
      (membersByTeamId.value[team.id] ?? []).forEach(member => {
        acc[member.id] = [...(acc[member.id] ?? []), team];
      });
      return acc;
    }, {})
  );

  return { teams, membersByTeamId, teamsByAgentId };
}
