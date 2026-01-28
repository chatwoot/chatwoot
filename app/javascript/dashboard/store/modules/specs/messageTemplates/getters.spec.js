import { getters } from '../../messageTemplates';
import { builderConfig, templates, uiFlags } from './fixtures';

const buildState = () => ({
  records: templates.map(template => ({ ...template })),
  builderConfig: { ...builderConfig },
  uiFlags: { ...uiFlags },
});

describe('#getters', () => {
  describe('#getUIFlags', () => {
    it('returns UI flags', () => {
      const state = buildState();
      const result = getters.getUIFlags(state);
      expect(result).toEqual(uiFlags);
    });
  });

  describe('#getTemplates', () => {
    it('returns templates sorted by ID descending', () => {
      const state = buildState();
      const result = getters.getTemplates(state);
      expect(result).toHaveLength(3);
      expect(result[0].id).toBe(3);
      expect(result[1].id).toBe(2);
      expect(result[2].id).toBe(1);
    });

    it('returns empty array when no templates', () => {
      const result = getters.getTemplates({ records: [] });
      expect(result).toEqual([]);
    });
  });

  describe('#getTemplatesByInbox', () => {
    it('filters templates by inbox ID', () => {
      const state = buildState();
      const result = getters.getTemplatesByInbox(state)(1);
      expect(result).toHaveLength(2);
      expect(result.every(t => t.inbox_id === 1)).toBe(true);
    });

    it('returns empty array for non-existent inbox', () => {
      const state = buildState();
      const result = getters.getTemplatesByInbox(state)(999);
      expect(result).toEqual([]);
    });

    it('returns templates for different inbox', () => {
      const state = buildState();
      const result = getters.getTemplatesByInbox(state)(2);
      expect(result).toHaveLength(1);
      expect(result[0].inbox_id).toBe(2);
    });
  });

  describe('#getTemplatesByStatus', () => {
    it('filters templates by approved status', () => {
      const state = buildState();
      const result = getters.getTemplatesByStatus(state)('approved');
      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('approved');
    });

    it('filters templates by pending status', () => {
      const state = buildState();
      const result = getters.getTemplatesByStatus(state)('pending');
      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('pending');
    });

    it('filters templates by rejected status', () => {
      const state = buildState();
      const result = getters.getTemplatesByStatus(state)('rejected');
      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('rejected');
    });

    it('returns empty array for non-existent status', () => {
      const state = buildState();
      const result = getters.getTemplatesByStatus(state)('invalid');
      expect(result).toEqual([]);
    });
  });

  describe('#getApprovedTemplates', () => {
    it('returns only approved templates', () => {
      const state = buildState();
      const result = getters.getApprovedTemplates(state);
      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('approved');
    });

    it('returns empty array when no approved templates', () => {
      const state = buildState();
      state.records = state.records.filter(
        template => template.status !== 'approved'
      );
      const result = getters.getApprovedTemplates(state);
      expect(result).toEqual([]);
    });
  });

  describe('#getTemplate', () => {
    it('returns template by ID', () => {
      const state = buildState();
      const result = getters.getTemplate(state)(1);
      expect(result).toBeDefined();
      expect(result.id).toBe(1);
    });

    it('returns template by numeric string ID', () => {
      const state = buildState();
      const result = getters.getTemplate(state)('2');
      expect(result).toBeDefined();
      expect(result.id).toBe(2);
    });

    it('returns undefined for non-existent ID', () => {
      const state = buildState();
      const result = getters.getTemplate(state)(999);
      expect(result).toBeUndefined();
    });

    it('handles empty records', () => {
      const emptyState = { records: [] };
      const result = getters.getTemplate(emptyState)(1);
      expect(result).toBeUndefined();
    });
  });

  describe('#getBuilderConfig', () => {
    it('returns current builder config', () => {
      const state = buildState();
      const result = getters.getBuilderConfig(state);
      expect(result).toEqual({ ...builderConfig });
    });

    it('returns empty object when no config', () => {
      const emptyState = { builderConfig: {} };
      const result = getters.getBuilderConfig(emptyState);
      expect(result).toEqual({});
    });
  });
});
