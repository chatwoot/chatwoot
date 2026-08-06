import { AUTOMATIONS } from './constants';
import { OPERATOR_TYPES_3 } from './operators';

describe('automation constants', () => {
  describe('conversation_resolved', () => {
    it('supports labels as a condition and action', () => {
      const { conditions, actions } = AUTOMATIONS.conversation_resolved;

      expect(conditions).toContainEqual({
        key: 'labels',
        name: 'LABELS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      });
      expect(actions).toEqual(
        expect.arrayContaining([
          { key: 'add_label', name: 'ADD_LABEL' },
          { key: 'remove_label', name: 'REMOVE_LABEL' },
        ])
      );
    });
  });
});
