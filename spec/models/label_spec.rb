require 'rails_helper'

RSpec.describe Label, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:parent).class_name('Label').optional(true).counter_cache(:children_count) }
    it { is_expected.to have_many(:children).class_name('Label').with_foreign_key('parent_id').dependent(:destroy).inverse_of(:parent) }
  end

  describe 'title validations' do
    it 'would not let you start title without numbers or letters' do
      label = FactoryBot.build(:label, title: '_12')
      expect(label.valid?).to be false
    end

    it 'would not let you use special characters' do
      label = FactoryBot.build(:label, title: 'jell;;2_12')
      expect(label.valid?).to be false
    end

    it 'would not allow space' do
      label = FactoryBot.build(:label, title: 'heeloo _12')
      expect(label.valid?).to be false
    end

    it 'allows foreign charactes' do
      label = FactoryBot.build(:label, title: '学中文_12')
      expect(label.valid?).to be true
    end

    it 'converts uppercase letters to lowercase' do
      label = FactoryBot.build(:label, title: 'Hello_World')
      expect(label.valid?).to be true
      expect(label.title).to eq 'hello_world'
    end

    it 'validates uniqueness of label name for account' do
      account = create(:account)
      label = FactoryBot.create(:label, account: account)
      duplicate_label = FactoryBot.build(:label, title: label.title, account: account)
      expect(duplicate_label.valid?).to be false
    end
  end

  describe 'hierarchy validations' do
    let!(:account) { create(:account) }
    let!(:label) { create(:label, account: account, title: 'parent_label') }

    context 'when creating circular reference' do
      let!(:child_label) { create(:label, account: account, parent: label, title: 'child') }

      it 'prevents setting itself as parent' do
        label.parent_id = label.id
        expect(label).not_to be_valid
        expect(label.errors[:parent_id]).to include('cannot be the same as the label')
      end

      it 'prevents circular reference through child' do
        label.parent_id = child_label.id
        expect(label).not_to be_valid
        expect(label.errors[:parent_id]).to include('would create a circular reference')
      end
    end

    context 'when nesting exceeds maximum depth' do
      let!(:level1) { create(:label, account: account, title: 'level1') }
      let!(:level2) { create(:label, account: account, parent: level1, title: 'level2') }
      let!(:level3) { create(:label, account: account, parent: level2, title: 'level3') }
      let!(:level4) { create(:label, account: account, parent: level3, title: 'level4') }
      let!(:level5) { create(:label, account: account, parent: level4, title: 'level5') }
      let!(:level6) { create(:label, account: account, parent: level5, title: 'level6') }

      it 'prevents nesting beyond maximum depth of 5' do
        level7 = build(:label, account: account, parent: level6, title: 'level7')
        expect(level7).not_to be_valid
        expect(level7.errors[:parent_id]).to include('would exceed maximum nesting depth of 5')
      end
    end

    context 'when parent belongs to different account' do
      let!(:other_account) { create(:account) }
      let!(:other_label) { create(:label, account: other_account, title: 'other_account_label') }

      it 'prevents setting parent from different account' do
        label.parent = other_label
        expect(label).not_to be_valid
        expect(label.errors[:parent_id]).to include('must belong to the same account')
      end

      it 'prevents creating label with parent from different account' do
        new_label = build(:label, account: account, parent: other_label, title: 'cross_account_child')
        expect(new_label).not_to be_valid
        expect(new_label.errors[:parent_id]).to include('must belong to the same account')
      end
    end
  end

  describe 'callbacks' do
    let!(:account) { create(:account) }

    describe '#calculate_depth' do
      let!(:parent) { create(:label, account: account, title: 'parent') }
      let!(:child) { create(:label, account: account, parent: parent, title: 'child') }
      let!(:grandchild) { create(:label, account: account, parent: child, title: 'grandchild') }

      it 'sets depth to 0 for root labels' do
        expect(parent.depth).to eq(0)
      end

      it 'calculates correct depth for child labels' do
        expect(child.depth).to eq(1)
        expect(grandchild.depth).to eq(2)
      end
    end
  end

  describe 'NULL value handling' do
    let!(:account) { create(:account) }

    context 'when depth and children_count are NULL' do
      let!(:label) { create(:label, account: account, title: 'null_test') }

      before do
        # Force NULL values directly in database - using update_columns is acceptable in tests
        # rubocop:disable Rails/SkipsModelValidations
        label.update_columns(depth: nil, children_count: nil)
        # rubocop:enable Rails/SkipsModelValidations
        label.reload
      end

      it 'returns 0 for depth method when value is NULL' do
        expect(label.read_attribute(:depth)).to be_nil
        expect(label.depth).to eq(0)
      end

      it 'returns 0 for children_count method when value is NULL' do
        expect(label.read_attribute(:children_count)).to be_nil
        expect(label.children_count).to eq(0)
      end

      it 'handles NULL depth in parent when calculating child depth' do
        child = create(:label, account: account, parent: label, title: 'child_of_null')
        expect(child.depth).to eq(1) # parent.depth (0 from NULL) + 1
      end

      it 'leaf? method works correctly with NULL children_count' do
        expect(label.children_count).to eq(0)
        expect(label.leaf?).to be(true)
      end

      it 'root? method works correctly regardless of depth value' do
        expect(label.root?).to be(true)
      end
    end

    context 'when creating labels with existing NULL values' do
      let!(:parent_with_null) { create(:label, account: account, title: 'parent_null') }

      before do
        # rubocop:disable Rails/SkipsModelValidations
        parent_with_null.update_columns(depth: nil, children_count: nil)
        # rubocop:enable Rails/SkipsModelValidations
        parent_with_null.reload
      end

      it 'correctly calculates depth for children of NULL depth parents' do
        child = create(:label, account: account, parent: parent_with_null, title: 'child1')
        grandchild = create(:label, account: account, parent: child, title: 'grandchild1')

        expect(child.depth).to eq(1)
        expect(grandchild.depth).to eq(2)
      end

      it 'updates children_count even when starting from NULL' do
        expect(parent_with_null.read_attribute(:children_count)).to be_nil

        create(:label, account: account, parent: parent_with_null, title: 'child1')
        parent_with_null.reload

        expect(parent_with_null.read_attribute(:children_count)).to eq(1)
      end
    end
  end

  describe 'scopes' do
    let!(:account) { create(:account) }
    let!(:root_label1) { create(:label, account: account, title: 'root1') }
    let!(:root_label2) { create(:label, account: account, title: 'root2') }
    # These child labels are needed to establish parent-child relationships for scope tests
    # rubocop:disable RSpec/LetSetup
    let!(:child_label1) { create(:label, account: account, parent: root_label1, title: 'child1') }
    let!(:child_label2) { create(:label, account: account, parent: root_label1, title: 'child2') }
    # rubocop:enable RSpec/LetSetup

    describe '.root_labels' do
      it 'returns only labels without parent' do
        expect(account.labels.root_labels).to contain_exactly(root_label1, root_label2)
      end
    end

    describe '.with_children' do
      it 'returns only labels that have children' do
        expect(account.labels.with_children).to contain_exactly(root_label1)
      end
    end
  end

  describe 'instance methods' do
    let!(:account) { create(:account) }
    let!(:root) { create(:label, account: account, title: 'root') }
    let!(:child1) { create(:label, account: account, parent: root, title: 'child1') }
    let!(:child2) { create(:label, account: account, parent: root, title: 'child2') }
    let!(:grandchild1) { create(:label, account: account, parent: child1, title: 'grandchild1') }
    let!(:grandchild2) { create(:label, account: account, parent: child1, title: 'grandchild2') }
    let!(:great_grandchild) { create(:label, account: account, parent: grandchild1, title: 'great_grandchild') }

    describe '#descendants' do
      it 'returns all descendants of a label' do
        expect(root.descendants).to contain_exactly(child1, child2, grandchild1, grandchild2, great_grandchild)
      end

      it 'returns correct descendants for child label' do
        expect(child1.descendants).to contain_exactly(grandchild1, grandchild2, great_grandchild)
      end

      it 'returns empty array for leaf labels' do
        expect(great_grandchild.descendants).to eq([])
      end
    end

    describe '#ancestors' do
      it 'returns all ancestors of a label' do
        expect(great_grandchild.ancestors).to eq([grandchild1, child1, root])
      end

      it 'returns correct ancestors for middle-level label' do
        expect(grandchild1.ancestors).to eq([child1, root])
      end

      it 'returns empty array for root labels' do
        expect(root.ancestors).to eq([])
      end
    end

    describe '#root?' do
      it 'returns true for labels without parent' do
        expect(root.root?).to be(true)
      end

      it 'returns false for labels with parent' do
        expect(child1.root?).to be(false)
        expect(grandchild1.root?).to be(false)
      end
    end

    describe '#leaf?' do
      it 'returns true for labels without children' do
        expect(child2.leaf?).to be(true)
        expect(grandchild2.leaf?).to be(true)
        expect(great_grandchild.leaf?).to be(true)
      end

      it 'returns false for labels with children' do
        expect(root.leaf?).to be(false)
        expect(child1.leaf?).to be(false)
      end
    end

    describe '#self_and_descendants' do
      it 'returns label and all its descendants' do
        expect(root.self_and_descendants).to contain_exactly(root, child1, child2, grandchild1, grandchild2, great_grandchild)
      end

      it 'returns only self for leaf labels' do
        expect(great_grandchild.self_and_descendants).to eq([great_grandchild])
      end
    end

    describe '#self_and_ancestors' do
      it 'returns label and all its ancestors' do
        expect(great_grandchild.self_and_ancestors).to eq([great_grandchild, grandchild1, child1, root])
      end

      it 'returns only self for root labels' do
        expect(root.self_and_ancestors).to eq([root])
      end
    end
  end

  describe 'conversation aggregation methods' do
    let!(:account) { create(:account) }
    let!(:parent_label) { create(:label, account: account, title: 'parent') }
    let!(:child_label) { create(:label, account: account, parent: parent_label, title: 'child') }
    let!(:grandchild_label) { create(:label, account: account, parent: child_label, title: 'grandchild') }

    let!(:inbox) { create(:inbox, account: account) }
    let!(:contact) { create(:contact, account: account) }

    let!(:parent_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let!(:child_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let!(:grandchild_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

    before do
      parent_conversation.update_labels([parent_label.title])
      child_conversation.update_labels([child_label.title])
      grandchild_conversation.update_labels([grandchild_label.title])
    end

    describe '#conversations' do
      it 'returns conversations tagged with the label' do
        expect(parent_label.conversations).to include(parent_conversation)
        expect(child_label.conversations).to include(child_conversation)
        expect(grandchild_label.conversations).to include(grandchild_conversation)
      end
    end

    describe '#aggregated_conversations' do
      it 'returns conversations from label and all descendants' do
        aggregated = parent_label.aggregated_conversations
        expect(aggregated).to include(parent_conversation, child_conversation, grandchild_conversation)
      end

      it 'returns conversations from label and its descendants for child label' do
        aggregated = child_label.aggregated_conversations
        expect(aggregated).to include(child_conversation, grandchild_conversation)
        expect(aggregated).not_to include(parent_conversation)
      end

      it 'returns only its own conversations for leaf label' do
        aggregated = grandchild_label.aggregated_conversations
        expect(aggregated).to include(grandchild_conversation)
        expect(aggregated).not_to include(parent_conversation, child_conversation)
      end
    end
  end

  describe 'counter cache' do
    let!(:account) { create(:account) }
    let!(:parent) { create(:label, account: account, title: 'parent') }

    it 'increments children_count when child is added' do
      expect do
        create(:label, account: account, parent: parent, title: 'child1')
      end.to change { parent.reload.children_count }.from(0).to(1)
    end

    context 'with NULL children_count' do
      let!(:parent_with_null) { create(:label, account: account, title: 'parent_null') }

      before do
        # rubocop:disable Rails/SkipsModelValidations
        parent_with_null.update_columns(children_count: nil)
        # rubocop:enable Rails/SkipsModelValidations
        parent_with_null.reload
      end

      it 'updates from NULL to 1 when first child is added' do
        expect(parent_with_null.read_attribute(:children_count)).to be_nil
        expect(parent_with_null.children_count).to eq(0)

        create(:label, account: account, parent: parent_with_null, title: 'child1')
        parent_with_null.reload

        expect(parent_with_null.read_attribute(:children_count)).to eq(1)
        expect(parent_with_null.children_count).to eq(1)
      end
    end

    it 'decrements children_count when child is removed' do
      child = create(:label, account: account, parent: parent, title: 'child1')
      expect(parent.reload.children_count).to eq(1)

      child.destroy
      expect(parent.reload.children_count).to eq(0)
    end

    it 'updates children_count when child parent is changed' do
      new_parent = create(:label, account: account, title: 'new_parent')
      child = create(:label, account: account, parent: parent, title: 'child1')

      expect(parent.reload.children_count).to eq(1)
      expect(new_parent.reload.children_count).to eq(0)

      child.update(parent: new_parent)

      expect(parent.reload.children_count).to eq(0)
      expect(new_parent.reload.children_count).to eq(1)
    end
  end

  describe '.after_update_commit' do
    let(:label) { create(:label) }

    it 'calls update job' do
      expect(Labels::UpdateJob).to receive(:perform_later).with('new-title', label.title, label.account_id)

      label.update(title: 'new-title')
    end

    it 'does not call update job if title is not updated' do
      expect(Labels::UpdateJob).not_to receive(:perform_later)

      label.update(description: 'new-description')
    end
  end
end
