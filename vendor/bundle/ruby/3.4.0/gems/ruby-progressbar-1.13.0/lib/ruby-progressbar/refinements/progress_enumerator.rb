class  ProgressBar
module Refinements
module Enumerator
  ARITY_ERROR_MESSAGE = 'Only two arguments allowed to be passed to ' \
                        'with_progressbar (item, progress_bar)'.freeze

  refine ::Enumerator do
    def with_progressbar(options = {}, &block)
      progress_bar = ProgressBar.create(options.merge(:starting_at => 0, :total => size))

      each do |item|
        progress_bar.increment

        next unless block

        yielded_args = []
        yielded_args << item         if block.arity > 0
        yielded_args << progress_bar if block.arity > 1

        fail ::ArgumentError, ARITY_ERROR_MESSAGE if block.arity > 2

        yield(*yielded_args)
      end
    end
  end
end
end
end
