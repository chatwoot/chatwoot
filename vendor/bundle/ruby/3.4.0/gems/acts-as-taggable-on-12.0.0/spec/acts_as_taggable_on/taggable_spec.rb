# encoding: utf-8
require 'spec_helper'

describe 'Taggable To Preserve Order' do
  before(:each) do
    @taggable = OrderedTaggableModel.new(name: 'Bob Jones')
  end


  it 'should have tag associations' do
    [:tags, :colours].each do |type|
      expect(@taggable.respond_to?(type)).to be_truthy
      expect(@taggable.respond_to?("#{type.to_s.singularize}_taggings")).to be_truthy
    end
  end

  it 'should have tag methods' do
    [:tags, :colours].each do |type|
      expect(@taggable.respond_to?("#{type.to_s.singularize}_list")).to be_truthy
      expect(@taggable.respond_to?("#{type.to_s.singularize}_list=")).to be_truthy
      expect(@taggable.respond_to?("all_#{type}_list")).to be_truthy
    end
  end

  it 'should return tag list in the order the tags were created' do
    # create
    @taggable.tag_list = 'rails, ruby, css'
    expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

    expect{
      @taggable.save
    }.to change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    expect(@taggable.tag_list).to eq(%w(rails ruby css))

    # update
    @taggable.tag_list = 'pow, ruby, rails'
    @taggable.save

    @taggable.reload
    expect(@taggable.tag_list).to eq(%w(pow ruby rails))

    # update with no change
    @taggable.tag_list = 'pow, ruby, rails'
    @taggable.save

    @taggable.reload
    expect(@taggable.tag_list).to eq(%w(pow ruby rails))

    # update to clear tags
    @taggable.tag_list = ''
    @taggable.save

    @taggable.reload
    expect(@taggable.tag_list).to be_empty
  end

  it 'should return tag objects in the order the tags were created' do
    # create
    @taggable.tag_list = 'pow, ruby, rails'
    expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

    expect {
      @taggable.save
    }.to change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    expect(@taggable.tags.map { |t| t.name }).to eq(%w(pow ruby rails))

    # update
    @taggable.tag_list = 'rails, ruby, css, pow'
    @taggable.save

    @taggable.reload
    expect(@taggable.tags.map { |t| t.name }).to eq(%w(rails ruby css pow))
  end

  it 'should return tag objects in tagging id order' do
    # create
    @taggable.tag_list = 'pow, ruby, rails'
    @taggable.save

    @taggable.reload
    ids = @taggable.tags.map { |t| t.taggings.first.id }
    expect(ids).to eq(ids.sort)

    # update
    @taggable.tag_list = 'rails, ruby, css, pow'
    @taggable.save

    @taggable.reload
    ids = @taggable.tags.map { |t| t.taggings.first.id }
    expect(ids).to eq(ids.sort)
  end
end

describe 'Taggable' do
  before(:each) do
    @taggable = TaggableModel.new(name: 'Bob Jones')
    @taggables = [@taggable, TaggableModel.new(name: 'John Doe')]
  end

  it 'should have tag types' do
    [:tags, :languages, :skills, :needs, :offerings].each do |type|
      expect(TaggableModel.tag_types).to include type
    end

    expect(@taggable.tag_types).to eq(TaggableModel.tag_types)
  end

  it 'should have tenant column' do
    expect(TaggableModel.tenant_column).to eq(:tenant_id)
  end

  it 'should have tag_counts_on' do
    expect(TaggableModel.tag_counts_on(:tags)).to be_empty

    @taggable.tag_list = %w(awesome epic)
    @taggable.save

    expect(TaggableModel.tag_counts_on(:tags).length).to eq(2)
    expect(@taggable.tag_counts_on(:tags).length).to eq(2)
  end

  context 'tag_counts on a collection' do
    context 'a select clause is specified on the collection' do
      it 'should return tag counts without raising an error' do
        expect(TaggableModel.tag_counts_on(:tags)).to be_empty

        @taggable.tag_list = %w(awesome epic)
        @taggable.save

        expect {
          expect(TaggableModel.select(:name).tag_counts_on(:tags).length).to eq(2)
        }.not_to raise_error
      end
    end
  end

  it 'should have tags_on' do
    expect(TaggableModel.tags_on(:tags)).to be_empty

    @taggable.tag_list = %w(awesome epic)
    @taggable.save

    expect(TaggableModel.tags_on(:tags).length).to eq(2)
    expect(@taggable.tags_on(:tags).length).to eq(2)
  end

  it 'should return [] right after create' do
    blank_taggable = TaggableModel.new(name: 'Bob Jones')
    expect(blank_taggable.tag_list).to be_empty
  end

  it 'should be able to create tags' do
    @taggable.skill_list = 'ruby, rails, css'
    expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

    expect{
      @taggable.save
    }.to change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    expect(@taggable.skill_list.sort).to eq(%w(ruby rails css).sort)
  end

  it 'should be able to create tags through the tag list directly' do
    @taggable.tag_list_on(:test).add('hello')
    expect(@taggable.tag_list_cache_on(:test)).to_not be_empty
    expect(@taggable.tag_list_on(:test)).to eq(['hello'])

    @taggable.save
    @taggable.save_tags

    @taggable.reload
    expect(@taggable.tag_list_on(:test)).to eq(['hello'])
  end

  it 'should differentiate between contexts' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.tag_list = 'ruby, bob, charlie'
    @taggable.save
    @taggable.reload
    expect(@taggable.skill_list).to include('ruby')
    expect(@taggable.skill_list).to_not include('bob')
  end

  it 'should be able to remove tags through list alone' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.save
    @taggable.reload
    expect(@taggable.skills.count).to eq(3)
    @taggable.skill_list = 'ruby, rails'
    @taggable.save
    @taggable.reload
    expect(@taggable.skills.count).to eq(2)
  end

  it 'should be able to select taggables by subset of tags using ActiveRelation methods' do
    @taggables[0].tag_list = 'bob'
    @taggables[1].tag_list = 'charlie'
    @taggables[0].skill_list = 'ruby'
    @taggables[1].skill_list = 'css'
    @taggables.each { |taggable| taggable.save }

    @found_taggables_by_tag = TaggableModel.joins(:tags).where(ActsAsTaggableOn.tags_table => {name: ['bob']})
    @found_taggables_by_skill = TaggableModel.joins(:skills).where(ActsAsTaggableOn.tags_table => {name: ['ruby']})

    expect(@found_taggables_by_tag).to include @taggables[0]
    expect(@found_taggables_by_tag).to_not include @taggables[1]
    expect(@found_taggables_by_skill).to include @taggables[0]
    expect(@found_taggables_by_skill).to_not include @taggables[1]
  end

  it 'should be able to find by tag' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').first).to eq(@taggable)
  end

  it 'should be able to get a count with find by tag when using a group by' do
    @taggable.skill_list = 'ruby'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').group(:created_at).count.count).to eq(1)
  end

  it 'can be used as scope' do
    @taggable.skill_list = 'ruby'
    @taggable.save
    untaggable_model = @taggable.untaggable_models.create!(name:'foobar')
    scope_tag = TaggableModel.tagged_with('ruby', any: 'distinct', order: 'taggable_models.name asc')
    expect(UntaggableModel.joins(:taggable_model).merge(scope_tag).except(:select)).to eq([untaggable_model])
  end

  it "shouldn't generate a query with DISTINCT by default" do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').to_sql).to_not match /DISTINCT/
  end

  it "should be able to find a tag using dates" do
    @taggable.skill_list = "ruby"
    @taggable.save
    today = Date.today.to_time.utc
    tomorrow = Date.tomorrow.to_time.utc

    expect(TaggableModel.tagged_with("ruby", :start_at => today, :end_at => tomorrow).count).to eq(1)
  end

  it "shouldn't be able to find a tag outside date range" do
    @taggable.skill_list = "ruby"
    @taggable.save

    expect(TaggableModel.tagged_with("ruby", :start_at => Date.today - 2.days, :end_at => Date.today - 1.day).count).to eq(0)
  end

  it 'should be able to find by tag with context' do
    @taggable.skill_list = 'ruby, rails, css, julia'
    @taggable.tag_list = 'bob, charlie, julia'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').first).to eq(@taggable)
    expect(TaggableModel.tagged_with('ruby, css').first).to eq(@taggable)
    expect(TaggableModel.tagged_with('bob', on: :skills).first).to_not eq(@taggable)
    expect(TaggableModel.tagged_with('bob', on: :tags).first).to eq(@taggable)
    expect(TaggableModel.tagged_with('julia', on: :skills).size).to eq(1)
    expect(TaggableModel.tagged_with('julia', on: :tags).size).to eq(1)
    expect(TaggableModel.tagged_with('julia', on: nil).size).to eq(2)
  end

  it 'should not care about case' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby')
    TaggableModel.create(name: 'Frank', tag_list: 'Ruby')

    expect(ActsAsTaggableOn::Tag.all.size).to eq(1)
    expect(TaggableModel.tagged_with('ruby').to_a).to eq(TaggableModel.tagged_with('Ruby').to_a)
  end

  it 'should be able to find by tags with other joins in the query' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.tag_list = 'bob, charlie'
    @taggable.save

    expect(TaggableModel.tagged_with(['bob', 'css'], :any => true).to_a).to eq([@taggable])

    bob = TaggableModel.create(:name => 'Bob', :tag_list => 'ruby, rails, css')
    frank = TaggableModel.create(:name => 'Frank', :tag_list => 'ruby, rails')
    charlie = TaggableModel.create(:name => 'Charlie', :skill_list => 'ruby, java')

    # Test for explicit distinct in select
    bob.untaggable_models.create!
    frank.untaggable_models.create!
    charlie.untaggable_models.create!

    expect(TaggableModel.select('distinct(taggable_models.id), taggable_models.*').joins(:untaggable_models).tagged_with(['css', 'java'], :any => true).to_a.sort).to eq([bob, charlie].sort)

    expect(TaggableModel.select('distinct(taggable_models.id), taggable_models.*').joins(:untaggable_models).tagged_with(['rails', 'ruby'], :any => false).to_a.sort).to eq([bob, frank].sort)
  end

  it 'should not care about case for unicode names', unless: using_sqlite? do
    ActsAsTaggableOn.strict_case_match = false
    TaggableModel.create(name: 'Anya', tag_list: 'ПРИВЕТ')
    TaggableModel.create(name: 'Igor', tag_list: 'привет')
    TaggableModel.create(name: 'Katia', tag_list: 'ПРИВЕТ')

    expect(ActsAsTaggableOn::Tag.all.size).to eq(1)
    expect(TaggableModel.tagged_with('привет').to_a).to eq(TaggableModel.tagged_with('ПРИВЕТ').to_a)
  end

  context 'should be able to create and find tags in languages without capitalization :' do
    ActsAsTaggableOn.strict_case_match = false
    {
        japanese: {name: 'Chihiro', tag_list: '日本の'},
        hebrew: {name: 'Salim', tag_list: 'עברית'},
        chinese: {name: 'Ieie', tag_list: '中国的'},
        arabic: {name: 'Yasser', tag_list: 'العربية'},
        emo: {name: 'Emo', tag_list: '✏'}
    }.each do |language, values|

      it language do
        TaggableModel.create(values)
        expect(TaggableModel.tagged_with(values[:tag_list]).count).to eq(1)
      end
    end
  end

  it 'should be able to get tag counts on model as a whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')
    expect(TaggableModel.tag_counts).to_not be_empty
    expect(TaggableModel.skill_counts).to_not be_empty
  end

  it 'should be able to get all tag counts on model as whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.all_tag_counts).to_not be_empty
    expect(TaggableModel.all_tag_counts(order: "#{ActsAsTaggableOn.tags_table}.id").first.count).to eq(3) # ruby
  end

  it 'should be able to get all tags on model as whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.all_tags).to_not be_empty
    expect(TaggableModel.all_tags(order: "#{ActsAsTaggableOn.tags_table}.id").first.name).to eq('ruby')
  end

  it 'should be able to use named scopes to chain tag finds by any tags by context' do
    bob = TaggableModel.create(name: 'Bob', need_list: 'rails', offering_list: 'c++')
    TaggableModel.create(name: 'Frank', need_list: 'css', offering_list: 'css')
    TaggableModel.create(name: 'Steve', need_list: 'c++', offering_list: 'java')

    # Let's only find those who need rails or css and are offering c++ or java
    expect(TaggableModel.tagged_with(['rails, css'], on: :needs, any: true).tagged_with(['c++', 'java'], on: :offerings, any: true).to_a).to eq([bob])
  end

  it 'should not return read-only records' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    expect(TaggableModel.tagged_with('ruby').first).to_not be_readonly
  end

  it 'should be able to get scoped tag counts' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').tag_counts(order: "#{ActsAsTaggableOn.tags_table}.id").first.count).to eq(2) # ruby
    expect(TaggableModel.tagged_with('ruby').skill_counts.first.count).to eq(1) # ruby
  end

  it 'should be able to get all scoped tag counts' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').all_tag_counts(order: "#{ActsAsTaggableOn.tags_table}.id").first.count).to eq(3) # ruby
  end

  it 'should be able to get all scoped tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').all_tags(order: "#{ActsAsTaggableOn.tags_table}.id").first.name).to eq('ruby')
  end

  it 'should only return tag counts for the available scope' do
    frank = TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby, java')

    expect(TaggableModel.tagged_with('rails').all_tag_counts.size).to eq(3)
    expect(TaggableModel.tagged_with('rails').all_tag_counts.any? { |tag| tag.name == 'java' }).to be_falsy

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    expect(TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tag_counts.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tag_counts.size).to eq(2)
  end

  it 'should only return tags for the available scope' do
    frank = TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby, java')

    expect(TaggableModel.tagged_with('rails').all_tags.count).to eq(3)
    expect(TaggableModel.tagged_with('rails').all_tags.any? { |tag| tag.name == 'java' }).to be_falsy

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    expect(TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tags.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tags.size).to eq(2)
  end

  it 'should be able to set a custom tag context list' do
    bob = TaggableModel.create(name: 'Bob')
    bob.set_tag_list_on(:rotors, 'spinning, jumping')
    expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
    bob.save
    bob.reload
    expect(bob.tags_on(:rotors)).to_not be_empty
  end

  it 'should be able to find tagged' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with('ruby', order: 'taggable_models.name').to_a).to eq([bob, frank, steve])
    expect(TaggableModel.tagged_with('ruby, rails', order: 'taggable_models.name').to_a).to eq([bob, frank])
    expect(TaggableModel.tagged_with(%w(ruby rails), order: 'taggable_models.name').to_a).to eq([bob, frank])
  end

  it 'should be able to find tagged with quotation marks' do
    bob = TaggableModel.create(name: 'Bob', tag_list: "fitter, happier, more productive, 'I love the ,comma,'")
    expect(TaggableModel.tagged_with("'I love the ,comma,'")).to include(bob)
  end

  it 'should be able to find tagged with invalid tags' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive')
    expect(TaggableModel.tagged_with('sad, happier')).to_not include(bob)
  end

  it 'should be able to find tagged with any tag' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with(%w(ruby java), order: 'taggable_models.name', any: true).to_a).to eq([bob, frank, steve])
    expect(TaggableModel.tagged_with(%w(c++ fitter), order: 'taggable_models.name', any: true).to_a).to eq([bob, steve])
    expect(TaggableModel.tagged_with(%w(depressed css), order: 'taggable_models.name', any: true).to_a).to eq([bob, frank])
  end

  it 'should be able to order by number of matching tags when matching any' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with(%w(ruby java), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
    expect(TaggableModel.tagged_with(%w(c++ fitter), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob])
    expect(TaggableModel.tagged_with(%w(depressed css), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([frank, bob])
    expect(TaggableModel.tagged_with(['fitter', 'happier', 'more productive', 'c++', 'java', 'ruby'], any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
    expect(TaggableModel.tagged_with(%w(c++ java ruby fitter), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
  end

  context 'wild: true' do
    it 'should use params as wildcards' do
      bob = TaggableModel.create(name: 'Bob', tag_list: 'bob, tricia')
      frank = TaggableModel.create(name: 'Frank', tag_list: 'bobby, jim')
      steve = TaggableModel.create(name: 'Steve', tag_list: 'john, patricia')
      jim = TaggableModel.create(name: 'Jim', tag_list: 'jim, steve')

      expect(TaggableModel.tagged_with(%w(bob tricia), wild: true, any: true).to_a.sort_by { |o| o.id }).to eq([bob, frank, steve])
      expect(TaggableModel.tagged_with(%w(bob tricia), wild: :prefix, any: true).to_a.sort_by { |o| o.id }).to eq([bob, steve])
      expect(TaggableModel.tagged_with(%w(bob tricia), wild: :suffix, any: true).to_a.sort_by { |o| o.id }).to eq([bob, frank])
      expect(TaggableModel.tagged_with(%w(cia), wild: :prefix, any: true).to_a.sort_by { |o| o.id }).to eq([bob, steve])
      expect(TaggableModel.tagged_with(%w(j), wild: :suffix, any: true).to_a.sort_by { |o| o.id }).to eq([frank, steve, jim])
      expect(TaggableModel.tagged_with(%w(bob tricia), wild: true, exclude: true).to_a).to eq([jim])
      expect(TaggableModel.tagged_with('ji', wild: true, any: true).to_a).to match_array([frank, jim])
    end
  end

  it 'should be able to find tagged on a custom tag context' do
    bob = TaggableModel.create(name: 'Bob')
    bob.set_tag_list_on(:rotors, 'spinning, jumping')
    expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
    bob.save

    expect(TaggableModel.tagged_with('spinning', on: :rotors).to_a).to eq([bob])
  end

  it 'should be able to use named scopes to chain tag finds' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, python')

    # Let's only find those productive Rails developers
    expect(TaggableModel.tagged_with('rails', on: :skills, order: 'taggable_models.name').to_a).to eq([bob, frank])
    expect(TaggableModel.tagged_with('happier', on: :tags, order: 'taggable_models.name').to_a).to eq([bob, steve])
    expect(TaggableModel.tagged_with('rails', on: :skills).tagged_with('happier', on: :tags).to_a).to eq([bob])
    expect(TaggableModel.tagged_with('rails').tagged_with('happier', on: :tags).to_a).to eq([bob])
  end

  it 'should be able to find tagged with only the matching tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'lazy, happier')
    TaggableModel.create(name: 'Frank', tag_list: 'fitter, happier, inefficient')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier')

    expect(TaggableModel.tagged_with('fitter, happier', match_all: true).to_a).to eq([steve])
  end

  it 'should be able to find tagged with only the matching tags for a context' do
    TaggableModel.create(name: 'Bob', tag_list: 'lazy, happier', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'fitter, happier, inefficient', skill_list: 'css')
    TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier', skill_list: 'ruby, rails, css')

    expect(TaggableModel.tagged_with('css', on: :skills, match_all: true).to_a).to eq([frank])
  end

  it 'should be able to find tagged with some excluded tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'happier, lazy')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'happier')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'happier')

    expect(TaggableModel.tagged_with('lazy', exclude: true)).to include(frank, steve)
    expect(TaggableModel.tagged_with('lazy', exclude: true).size).to eq(2)
  end

  it 'should return an empty scope for empty tags' do
    ['', ' ', nil, []].each do |tag|
      expect(TaggableModel.tagged_with(tag)).to be_empty
    end
  end

  it 'should options key not be deleted' do
    options = {:exclude => true}
    TaggableModel.tagged_with("foo", options)
    expect(options).to eq({:exclude => true})
  end

  it 'should not delete tags if not updated' do
    model = TaggableModel.create(name: 'foo', tag_list: 'ruby, rails, programming')
    model.update(name: 'bar')
    model.reload
    expect(model.tag_list.sort).to eq(%w(ruby rails programming).sort)
  end

  context 'Duplicates' do
    context 'should not create duplicate taggings' do
      let(:bob) { TaggableModel.create(name: 'Bob') }
      context 'case sensitive' do
        it '#add' do
          expect {
            bob.tag_list.add 'happier'
            bob.tag_list.add 'happier'
            bob.tag_list.add 'happier', 'rich', 'funny'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(3)
        end
        it '#<<' do
          expect {
            bob.tag_list << 'social'
            bob.tag_list << 'social'
            bob.tag_list << 'social' << 'wow'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(2)

        end

        it 'unicode' do

          expect {
            bob.tag_list.add 'ПРИВЕТ'
            bob.tag_list.add 'ПРИВЕТ'
            bob.tag_list.add 'ПРИВЕТ', 'ПРИВЕТ'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(1)

        end

        it '#=' do
          expect {
            bob.tag_list = ['Happy', 'Happy']
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(1)
        end
      end
      context 'case insensitive' do
        before(:all) { ActsAsTaggableOn.force_lowercase = true }
        after(:all) { ActsAsTaggableOn.force_lowercase = false }

        it '#<<' do
          expect {
            bob.tag_list << 'Alone'
            bob.tag_list << 'AloNe'
            bob.tag_list << 'ALONE' << 'In The dark'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(2)

        end

        it '#add' do
          expect {
            bob.tag_list.add 'forever'
            bob.tag_list.add 'ForEver'
            bob.tag_list.add 'FOREVER', 'ALONE'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(2)
        end

        it 'unicode' do

          expect {
            bob.tag_list.add 'ПРИВЕТ'
            bob.tag_list.add 'привет', 'Привет'
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(1)

        end

        it '#=' do
          expect {
            bob.tag_list = ['Happy', 'HAPPY']
            bob.save
          }.to change(ActsAsTaggableOn::Tagging, :count).by(1)
        end


      end


    end

    it 'should not duplicate tags' do
      connor = TaggableModel.new(name: 'Connor', tag_list: 'There, can, be, only, one')

      allow(ActsAsTaggableOn::Tag).to receive(:create).and_call_original
      expect(ActsAsTaggableOn::Tag).to receive(:create).with(name: 'can') do
        # Simulate concurrent tag creation
        ActsAsTaggableOn::Tag.new(name: 'can').save!

        raise ActiveRecord::RecordNotUnique
      end

      expect(ActsAsTaggableOn::Tag).to receive(:create).with(name: 'be') do
        # Simulate concurrent tag creation
        ActsAsTaggableOn::Tag.new(name: 'be').save!

        raise ActiveRecord::RecordNotUnique
      end

      expect { connor.save! }.to change(ActsAsTaggableOn::Tag, :count).by(5)

      %w[There can only be one].each do |tag|
        expect(TaggableModel.tagged_with(tag).count).to eq(1)
      end
    end
  end

  describe 'Associations' do
    before(:each) do
      @taggable = TaggableModel.create(tag_list: 'awesome, epic')
    end

    it 'should not remove tags when creating associated objects' do
      @taggable.untaggable_models.create!
      @taggable.reload
      expect(@taggable.tag_list.size).to eq(2)
    end
  end

  describe 'grouped_column_names_for method' do
    it 'should return all column names joined for Tag GROUP clause' do
      # NOTE: type column supports an STI Tag subclass in the test suite, though
      # isn't included by default in the migration generator
      expect(@taggable.grouped_column_names_for(ActsAsTaggableOn::Tag))
      .to eq("#{ActsAsTaggableOn.tags_table}.id, #{ActsAsTaggableOn.tags_table}.name, #{ActsAsTaggableOn.tags_table}.taggings_count, #{ActsAsTaggableOn.tags_table}.type")
    end

    it 'should return all column names joined for TaggableModel GROUP clause' do
      expect(@taggable.grouped_column_names_for(TaggableModel)).to eq('taggable_models.id, taggable_models.name, taggable_models.type, taggable_models.tenant_id')
    end

    it 'should return all column names joined for NonStandardIdTaggableModel GROUP clause' do
      expect(@taggable.grouped_column_names_for(TaggableModel)).to eq("taggable_models.#{TaggableModel.primary_key}, taggable_models.name, taggable_models.type, taggable_models.tenant_id")
    end
  end

  describe 'NonStandardIdTaggable' do
    before(:each) do
      @taggable = NonStandardIdTaggableModel.new(name: 'Bob Jones')
      @taggables = [@taggable, NonStandardIdTaggableModel.new(name: 'John Doe')]
    end

    it 'should have tag types' do
      [:tags, :languages, :skills, :needs, :offerings].each do |type|
        expect(NonStandardIdTaggableModel.tag_types).to include type
      end

      expect(@taggable.tag_types).to eq(NonStandardIdTaggableModel.tag_types)
    end

    it 'should have tag_counts_on' do
      expect(NonStandardIdTaggableModel.tag_counts_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(NonStandardIdTaggableModel.tag_counts_on(:tags).length).to eq(2)
      expect(@taggable.tag_counts_on(:tags).length).to eq(2)
    end

    it 'should have tags_on' do
      expect(NonStandardIdTaggableModel.tags_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(NonStandardIdTaggableModel.tags_on(:tags).length).to eq(2)
      expect(@taggable.tags_on(:tags).length).to eq(2)
    end

    it 'should be able to create tags' do
      @taggable.skill_list = 'ruby, rails, css'
      expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

      expect {
        @taggable.save
      }.to change(ActsAsTaggableOn::Tag, :count).by(3)

      @taggable.reload
      expect(@taggable.skill_list.sort).to eq(%w(ruby rails css).sort)
    end

    it 'should be able to create tags through the tag list directly' do
      @taggable.tag_list_on(:test).add('hello')
      expect(@taggable.tag_list_cache_on(:test)).to_not be_empty
      expect(@taggable.tag_list_on(:test)).to eq(['hello'])

      @taggable.save
      @taggable.save_tags

      @taggable.reload
      expect(@taggable.tag_list_on(:test)).to eq(['hello'])
    end
  end

  describe 'Autogenerated methods' do
    it 'should be overridable' do
      expect(TaggableModel.create(tag_list: 'woo').tag_list_submethod_called).to be_truthy
    end
  end

  # See https://github.com/mbleigh/acts-as-taggable-on/pull/457 for details
  context 'tag_counts and aggreating scopes, compatibility with MySQL ' do
    before(:each) do
      TaggableModel.new(:name => 'Barb Jones').tap { |t| t.tag_list = %w(awesome fun) }.save
      TaggableModel.new(:name => 'John Doe').tap { |t| t.tag_list = %w(cool fun hella) }.save
      TaggableModel.new(:name => 'Jo Doe').tap { |t| t.tag_list = %w(curious young naive sharp) }.save

      TaggableModel.all.each { |t| t.save }
    end

    context 'Model.limit(x).tag_counts.sum(:tags_count)' do
      it 'should not break on Mysql' do
        expect(TaggableModel.limit(2).tag_counts.sum('tags_count').to_i).to eq(5)
      end
    end

    context 'regression prevention, just making sure these esoteric queries still work' do
      context 'Model.tag_counts.limit(x)' do
        it 'should limit the tag objects (not very useful, of course)' do
          array_of_tag_counts = TaggableModel.tag_counts.limit(2)
          expect(array_of_tag_counts.count).to eq(2)
        end
      end

      context 'Model.tag_counts.sum(:tags_count)' do
        it 'should limit the total tags used' do
          expect(TaggableModel.tag_counts.sum(:tags_count).to_i).to eq(9)
        end
      end

      context 'Model.tag_counts.limit(2).sum(:tags_count)' do
        it 'limit should have no effect; this is just a sanity check' do
          expect(TaggableModel.tag_counts.limit(2).sum(:tags_count).to_i).to eq(9)
        end
      end
    end
  end
end

describe 'Taggable model with json columns', if: postgresql_support_json? do
  before(:each) do
    @taggable = TaggableModelWithJson.new(:name => 'Bob Jones')
    @taggables = [@taggable, TaggableModelWithJson.new(:name => 'John Doe')]
  end

  it 'should be able to find by tag with context' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.tag_list = 'bob, charlie'
    @taggable.save

    expect(TaggableModelWithJson.tagged_with('ruby').first).to eq(@taggable)
    expect(TaggableModelWithJson.tagged_with('ruby, css').first).to eq(@taggable)
    expect(TaggableModelWithJson.tagged_with('bob', :on => :skills).first).to_not eq(@taggable)
    expect(TaggableModelWithJson.tagged_with('bob', :on => :tags).first).to eq(@taggable)
  end

  it 'should be able to find tagged with any tag' do
    bob = TaggableModelWithJson.create(:name => 'Bob', :tag_list => 'fitter, happier, more productive', :skill_list => 'ruby, rails, css')
    frank = TaggableModelWithJson.create(:name => 'Frank', :tag_list => 'weaker, depressed, inefficient', :skill_list => 'ruby, rails, css')
    steve = TaggableModelWithJson.create(:name => 'Steve', :tag_list => 'fitter, happier, more productive', :skill_list => 'c++, java, ruby')

    expect(TaggableModelWithJson.tagged_with(%w(ruby java), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, frank, steve])
    expect(TaggableModelWithJson.tagged_with(%w(c++ fitter), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, steve])
    expect(TaggableModelWithJson.tagged_with(%w(depressed css), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, frank])
  end
end
