import { getters } from '../../labels';
import labels from './fixtures';
describe('#getters', () => {
  it('getLabels', () => {
    const state = { records: labels };
    expect(getters.getLabels(state)).toEqual(labels);
  });

  it('getLabelsOnSidebar', () => {
    const state = { records: labels };
    const sidebarLabels = getters.getLabelsOnSidebar(state);
    expect(sidebarLabels).toHaveLength(2);
    expect(sidebarLabels[0].id).toBe(1);
    expect(sidebarLabels[1].id).toBe(8);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });

  it('getRootLabels', () => {
    const state = { records: labels };
    const rootLabels = getters.getRootLabels(state);
    expect(rootLabels).toHaveLength(3); // Now includes legacy-label-null
    expect(rootLabels[0].id).toBe(1);
    expect(rootLabels[1].id).toBe(7);
    expect(rootLabels[2].id).toBe(8);
  });

  it('getLabelsByParentId', () => {
    const state = { records: labels };
    const getLabelsByParent = getters.getLabelsByParentId(state);

    const childrenOf1 = getLabelsByParent(1);
    expect(childrenOf1).toHaveLength(2);
    expect(childrenOf1[0].id).toBe(4);
    expect(childrenOf1[1].id).toBe(5);

    const childrenOf5 = getLabelsByParent(5);
    expect(childrenOf5).toHaveLength(1);
    expect(childrenOf5[0].id).toBe(6);
  });

  it('getLabelById', () => {
    const state = { records: labels };
    const getLabelById = getters.getLabelById(state);
    expect(getLabelById(1).title).toBe('customer-support');
    expect(getLabelById(6).title).toBe('enterprise');
    expect(getLabelById(99)).toBeUndefined();
  });

  it('getLabelsTree', () => {
    const state = { records: labels };
    const mockGetters = {
      getRootLabels: labels.filter(l => !l.parent_id),
      getLabelsByParentId: parentId =>
        labels.filter(l => l.parent_id === parentId),
    };

    const tree = getters.getLabelsTree(state, mockGetters);
    expect(tree).toHaveLength(3); // Now includes legacy-label-null
    expect(tree[0].id).toBe(1);
    expect(tree[0].children).toHaveLength(2);
    expect(tree[0].children[0].id).toBe(4);
    expect(tree[0].children[1].id).toBe(5);
    expect(tree[0].children[1].children).toHaveLength(1);
    expect(tree[0].children[1].children[0].id).toBe(6);
  });

  it('getLabelsWithHierarchy', () => {
    const state = { records: labels };
    const mockGetters = {
      getLabelsTree: getters.getLabelsTree(state, {
        getRootLabels: labels.filter(l => !l.parent_id),
        getLabelsByParentId: parentId =>
          labels.filter(l => l.parent_id === parentId),
      }),
    };

    const hierarchicalLabels = getters.getLabelsWithHierarchy(
      state,
      mockGetters
    );
    expect(hierarchicalLabels).toHaveLength(7);

    expect(hierarchicalLabels[0].indent).toBe(0); // customer-support
    expect(hierarchicalLabels[1].indent).toBe(1); // saas-customer
    expect(hierarchicalLabels[2].indent).toBe(1); // hosted-customer
    expect(hierarchicalLabels[3].indent).toBe(2); // enterprise
    expect(hierarchicalLabels[4].indent).toBe(0); // billing-enquiry
    expect(hierarchicalLabels[5].indent).toBe(0); // legacy-label-null
    expect(hierarchicalLabels[6].indent).toBe(1); // child-of-null
  });

  describe('NULL value handling', () => {
    it('getRootLabels includes labels with NULL depth', () => {
      const state = { records: labels };
      const rootLabels = getters.getRootLabels(state);

      // Should include labels with parent_id: null regardless of depth value
      const nullLabel = rootLabels.find(l => l.id === 8);
      expect(nullLabel).toBeDefined();
      expect(nullLabel.depth).toBe(null);
      expect(nullLabel.children_count).toBe(null);
    });

    it('getLabelsByParentId works with parent having NULL children_count', () => {
      const state = { records: labels };
      const getLabelsByParent = getters.getLabelsByParentId(state);

      // Label 8 has NULL children_count but has child (label 9)
      const childrenOfNull = getLabelsByParent(8);
      expect(childrenOfNull).toHaveLength(1);
      expect(childrenOfNull[0].id).toBe(9);
    });

    it('getLabelsTree handles labels with NULL values', () => {
      const state = { records: labels };
      const mockGetters = {
        getRootLabels: labels.filter(l => !l.parent_id),
        getLabelsByParentId: parentId =>
          labels.filter(l => l.parent_id === parentId),
      };

      const tree = getters.getLabelsTree(state, mockGetters);

      // Find the label with NULL values
      const nullLabel = tree.find(l => l.id === 8);
      expect(nullLabel).toBeDefined();
      expect(nullLabel.depth).toBe(null);
      expect(nullLabel.children_count).toBe(null);
      expect(nullLabel.children).toHaveLength(1);
      expect(nullLabel.children[0].id).toBe(9);
    });
  });
});
