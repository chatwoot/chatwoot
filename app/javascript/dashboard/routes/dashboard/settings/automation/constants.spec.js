import { AUTOMATIONS } from './constants';
import { OPERATOR_TYPES_3 } from './operators';

describe('automation constants', () => {
  describe('conversation_resolved', () => {
    it('supports labels as a condition', () => {
      const { conditions } = AUTOMATIONS.conversation_resolved;

      expect(conditions).toContainEqual({
        key: 'labels',
        name: 'LABELS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      });
    });
  });
});
