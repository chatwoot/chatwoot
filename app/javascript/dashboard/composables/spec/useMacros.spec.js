import { describe, it, expect, vi } from 'vitest';
import { useMacros } from '../useMacros';
import { useStoreGetters } from 'dashboard/composables/store';
import { PRIORITY_CONDITION_VALUES } from 'dashboard/helper/automationHelper.js';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/helper/automationHelper.js');

describe('useMacros', () => {
  const mockLabels = [{ title: 'Label1' }, { title: 'Label2' }];
  const mockTeams = [
    { id: 1, name: 'Team1' },
    { id: 2, name: 'Team2' },
  ];
  const mockAgents = [
    { id: 1, name: 'Agent1' },
    { id: 2, name: 'Agent2' },
  ];

  beforeEach(() => {
    useStoreGetters.mockReturnValue({
      'labels/getLabels': { value: mockLabels },
      'teams/getTeams': { value: mockTeams },
      'agents/getAgents': { value: mockAgents },
    });
  });

  it('returns teams for assign_team and send_email_to_team types', () => {
    const { getMacroDropdownValues } = useMacros();
    expect(getMacroDropdownValues('assign_team')).toEqual(mockTeams);
    expect(getMacroDropdownValues('send_email_to_team')).toEqual(mockTeams);
  });

  it('returns agents with "Self" option for assign_agent type', () => {
    const { getMacroDropdownValues } = useMacros();
    expect(getMacroDropdownValues('assign_agent')).toEqual([
      { id: 'self', name: 'Self' },
      ...mockAgents,
    ]);
  });

  it('returns formatted labels for add_label and remove_label types', () => {
    const { getMacroDropdownValues } = useMacros();
    const expectedLabels = mockLabels.map(i => ({
      id: i.title,
      name: i.title,
    }));
    expect(getMacroDropdownValues('add_label')).toEqual(expectedLabels);
    expect(getMacroDropdownValues('remove_label')).toEqual(expectedLabels);
  });

  it('returns PRIORITY_CONDITION_VALUES for change_priority type', () => {
    const { getMacroDropdownValues } = useMacros();
    expect(getMacroDropdownValues('change_priority')).toEqual(
      PRIORITY_CONDITION_VALUES
    );
  });

  it('returns an empty array for unknown types', () => {
    const { getMacroDropdownValues } = useMacros();
    expect(getMacroDropdownValues('unknown_type')).toEqual([]);
  });
});
