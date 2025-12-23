shared_examples_for 'does not remove empty strings on error' do
  it 'does not remove empty strings on error' do |example|
    key = 'mock-redis-test:not-a-string'

    method = method_from_description(example)
    args = args_for_method(method).unshift(key)

    @redises.set(key, '')
    lambda do
      @redises.send(method, *args)
    end.should raise_error(defined?(default_error) ? default_error : RuntimeError)
    @redises.get(key).should == ''
  end
end
