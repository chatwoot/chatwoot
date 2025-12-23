shared_examples_for 'a sortable' do
  it 'returns empty array on nil' do
    @redises.sort(nil).should == []
  end

  context 'ordering' do
    it 'orders ascending by default' do
      @redises.sort(@key).should == %w[1 2]
    end

    it 'orders by descending when specified' do
      @redises.sort(@key, :order => 'DESC').should == %w[2 1]
    end
  end

  context 'projections' do
    it 'projects element when :get is "#"' do
      @redises.sort(@key, :get => '#').should == %w[1 2]
    end

    it 'projects through a key pattern' do
      @redises.sort(@key, :get => 'mock-redis-test:values_*').should == %w[a b]
    end

    it 'projects through a key pattern and reflects element' do
      @redises.sort(@key, :get => ['#', 'mock-redis-test:values_*']).should == [%w[1 a], %w[2 b]]
    end

    it 'projects through a hash key pattern' do
      @redises.sort(@key, :get => 'mock-redis-test:hash_*->key').should == %w[x y]
    end
  end

  context 'weights' do
    it 'weights by projecting through a key pattern' do
      @redises.sort(@key, :by => 'mock-redis-test:weight_*').should == %w[2 1]
    end

    it 'weights by projecting through a key pattern and a specific order' do
      @redises.sort(@key, :order => 'DESC', :by => 'mock-redis-test:weight_*').should == %w[1 2]
    end
  end

  context 'limit' do
    it 'only returns requested window in the enumerable' do
      @redises.sort(@key, :limit => [0, 1]).should == ['1']
    end
  end

  context 'store' do
    it 'stores into another key' do
      @redises.sort(@key, :store => 'mock-redis-test:some_bucket').should == 2
      @redises.lrange('mock-redis-test:some_bucket', 0, -1).should == %w[1 2]
    end
  end
end
