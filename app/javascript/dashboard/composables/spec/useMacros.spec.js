import { describe, it, expect, vi } from 'vitest';
import { useMacros } from '../useMacros';
import { useStoreGetters } from 'dashboard/composables/store';
import { PRIORITY_CONDITION_VALUES } from 'dashboard/helper/automationHelper.js';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/helper/automationHelper.js');

describe('useMacros', () => {
  const mockLabels = [
    {
      id: 6,
      title: 'sales',
      description: 'sales team',
      color: '#8EA20F',
      show_on_sidebar: true,
    },
    {
      id: 2,
      title: 'billing',
      description: 'billing',
      color: '#4077DA',
      show_on_sidebar: true,
    },
    {
      id: 1,
      title: 'snoozed',
      description: 'Items marked for later',
      color: '#D12F42',
      show_on_sidebar: true,
    },
    {
      id: 5,
      title: 'mobile-app',
      description: 'tech team',
      color: '#2DB1CC',
      show_on_sidebar: true,
    },
    {
      id: 14,
      title: 'human-resources-department-with-long-title',
      description: 'Test',
      color: '#FF6E09',
      show_on_sidebar: true,
    },
    {
      id: 22,
      title: 'priority',
      description: 'For important sales leads',
      color: '#7E7CED',
      show_on_sidebar: true,
    },
  ];
  const mockTeams = [
    {
      id: 1,
      name: '⚙️ sales team',
      description: 'This is our internal sales team',
      allow_auto_assign: true,
      account_id: 1,
      is_member: true,
    },
    {
      id: 2,
      name: '🤷‍♂️ fayaz',
      description: 'Test',
      allow_auto_assign: true,
      account_id: 1,
      is_member: true,
    },
    {
      id: 3,
      name: '🇮🇳 apac sales',
      description: 'Sales team for France Territory',
      allow_auto_assign: true,
      account_id: 1,
      is_member: true,
    },
  ];
  const mockAgents = [
    {
      id: 1,
      account_id: 1,
      availability_status: 'offline',
      auto_offline: true,
      confirmed: true,
      email: 'john@doe.com',
      available_name: 'John Doe',
      name: 'John Doe',
      role: 'agent',
      thumbnail:
        'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBUZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--746506837470c1a3dd063e90211ba2386963d52f/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2QzNKbGMybDZaVWtpRERJMU1IZ3lOVEFHT3daVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--e0e35266e8ed66e90c51be02408be8a022aca545/batman_90804.png',
    },
    {
      id: 9,
      account_id: 1,
      availability_status: 'offline',
      auto_offline: true,
      confirmed: true,
      email: 'clark@kent.com',
      available_name: 'Clark Kent',
      name: 'Clark Kent',
      role: 'agent',
      thumbnail: '',
    },
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
