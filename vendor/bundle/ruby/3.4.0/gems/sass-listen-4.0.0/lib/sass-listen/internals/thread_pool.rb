module SassListen
  # @private api
  module Internals
    module ThreadPool
      def self.add(&block)
        Thread.new { block.call }.tap do |th|
          (@threads ||= Queue.new) << th
        end
      end

      def self.stop
        return unless @threads ||= nil
        return if @threads.empty? # return to avoid using possibly stubbed Queue

        killed = Queue.new
        # You can't kill a read on a descriptor in JRuby, so let's just
        # ignore running threads (listen rb-inotify waiting for disk activity
        # before closing)  pray threads die faster than they are created...
        limit = RUBY_ENGINE == 'jruby' ? [1] : []

        killed << @threads.pop.kill until @threads.empty?
        until killed.empty?
          th = killed.pop
          th.join(*limit) unless th[:listen_blocking_read_thread]
        end
      end
    end
  end
end
