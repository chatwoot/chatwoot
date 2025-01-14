import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useFilter } from '../useFilter';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

// Mock the dependencies
vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');

describe('useFilter', () => {
  // Setup mocks
  beforeEach(() => {
    vi.mocked(useStore).mockReturnValue({
      getters: {
        'attributes/getAttributesByModel': vi.fn(),
      },
    });
    vi.mocked(useI18n).mockReturnValue({
      t: vi.fn(key => key),
    });
  });

  it('should return the correct functions', () => {
    const {
      setFilterAttributes,
      initializeStatusAndAssigneeFilterToModal,
      initializeInboxTeamAndLabelFilterToModal,
    } = useFilter({ filteri18nKey: 'TEST', attributeModel: 'conversation' });

    expect(setFilterAttributes).toBeDefined();
    expect(initializeStatusAndAssigneeFilterToModal).toBeDefined();
    expect(initializeInboxTeamAndLabelFilterToModal).toBeDefined();
  });

  describe('setFilterAttributes', () => {
    it('should return filterGroups and filterTypes', () => {
      const mockAttributes = [
        {
          attribute_key: 'test_key',
          attribute_display_name: 'Test Name',
          attribute_display_type: 'text',
        },
      ];
      vi.mocked(useStore)().getters[
        'attributes/getAttributesByModel'
      ].mockReturnValue(mockAttributes);

      const { setFilterAttributes } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = setFilterAttributes();

      expect(result).toHaveProperty('filterGroups');
      expect(result).toHaveProperty('filterTypes');
      expect(result.filterGroups.length).toBeGreaterThan(0);
      expect(result.filterTypes.length).toBeGreaterThan(0);
    });
  });

  describe('initializeStatusAndAssigneeFilterToModal', () => {
    it('should return status filter when activeStatus is provided', () => {
      const { initializeStatusAndAssigneeFilterToModal } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = initializeStatusAndAssigneeFilterToModal('open', {}, '');

      expect(result).toEqual({
        attribute_key: 'status',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          { id: 'open', name: 'CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT' },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    });

    it('should return null when no active filters', () => {
      const { initializeStatusAndAssigneeFilterToModal } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = initializeStatusAndAssigneeFilterToModal('', {}, '');

      expect(result).toBeNull();
    });
  });

  describe('initializeInboxTeamAndLabelFilterToModal', () => {
    it('should return filters for inbox, team, and label when provided', () => {
      const { initializeInboxTeamAndLabelFilterToModal } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = initializeInboxTeamAndLabelFilterToModal(
        1,
        { name: 'Inbox 1' },
        2,
        [{ id: 2, name: 'Team 2' }],
        'Label 1'
      );

      expect(result).toHaveLength(3);
      expect(result[0]).toHaveProperty('attribute_key', 'inbox_id');
      expect(result[1]).toHaveProperty('attribute_key', 'team_id');
      expect(result[2]).toHaveProperty('attribute_key', 'labels');
    });

    it('should return empty array when no filters are provided', () => {
      const { initializeInboxTeamAndLabelFilterToModal } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = initializeInboxTeamAndLabelFilterToModal(
        null,
        null,
        null,
        null,
        null
      );

      expect(result).toEqual([]);
    });

    it('should return only inbox filter when only inbox is provided', () => {
      const { initializeInboxTeamAndLabelFilterToModal } = useFilter({
        filteri18nKey: 'TEST',
        attributeModel: 'conversation',
      });
      const result = initializeInboxTeamAndLabelFilterToModal(
        1,
        { name: 'Inbox 1' },
        null,
        null,
        null
      );

      expect(result).toHaveLength(1);
      expect(result[0]).toHaveProperty('attribute_key', 'inbox_id');
    });
  });
});
