shared_examples_for 'a list-only command' do
  it 'raises an error for non-list values' do |example|
    key = 'mock-redis-test:list-only'

    method = method_from_description(example)
    args = args_for_method(method).unshift(key)

    @redises.set(key, 1)
    lambda do
      @redises.send(method, *args)
    end.should raise_error(defined?(default_error) ? default_error : RuntimeError)
  end

  it_should_behave_like 'does not remove empty strings on error'
end
