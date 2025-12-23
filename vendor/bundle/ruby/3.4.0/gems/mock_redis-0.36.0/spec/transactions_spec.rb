require 'spec_helper'

describe 'transactions (multi/exec/discard)' do
  before(:each) do
    @redises.discard rescue nil
  end

  context '#multi' do
    it "responds with 'OK'" do
      @redises.multi.should == 'OK'
    end

    it 'does not permit nesting' do
      @redises.multi
      lambda do
        @redises.multi
      end.should raise_error(Redis::CommandError, 'ERR MULTI calls can not be nested')
    end

    it 'cleans state of transaction wrapper if exception occurs during transaction' do
      lambda do
        @redises.mock.multi do |_r|
          raise "i'm a command that fails"
        end
      end.should raise_error(RuntimeError)

      # before the fix this used to raised a #<RuntimeError: ERR MULTI calls can not be nested>
      lambda do
        @redises.mock.multi do |r|
          # do stuff that succeed
          r.set(nil, 'string')
        end
      end.should_not raise_error
    end
  end

  context '#blocks' do
    it 'implicitly runs exec when finished' do
      @redises.set('counter', 5)
      @redises.multi do |r|
        r.set('test', 1)
        r.incr('counter')
      end
      @redises.get('counter').should eq '6'
      @redises.get('test').should eq '1'
    end

    it 'permits nesting via blocks' do
      # Have to use only the mock here. redis-rb has a bug in it where
      # nested #multi calls raise NoMethodError because it gets a nil
      # where it's not expecting one.
      @redises.mock.multi do |r|
        lambda do
          r.multi {}
        end.should_not raise_error
      end
    end

    it 'allows pipelined calls within multi blocks' do
      @redises.set('counter', 5)
      @redises.multi do |r|
        r.pipelined do |pr|
          pr.set('test', 1)
          pr.incr('counter')
        end
      end
      @redises.get('counter').should eq '6'
      @redises.get('test').should eq '1'
    end

    it 'allows blocks within multi blocks' do
      @redises.set('foo', 'bar')
      @redises.set('fuu', 'baz')

      result = nil

      @redises.multi do |r|
        result = r.mget('foo', 'fuu') { |reply| reply.map(&:upcase) }
        r.del('foo', 'fuu')
      end

      result.value.should eq %w[BAR BAZ]
      @redises.get('foo').should eq nil
      @redises.get('fuu').should eq nil
    end
  end

  context '#discard' do
    it "responds with 'OK' after #multi" do
      @redises.multi
      @redises.discard.should eq 'OK'
    end

    it "can't be run outside of #multi/#exec" do
      lambda do
        @redises.discard
      end.should raise_error(Redis::CommandError)
    end
  end

  context '#exec' do
    it 'raises an error outside of #multi' do
      lambda do
        @redises.exec.should raise_error
      end
    end
  end

  context 'saving up commands for later' do
    before(:each) do
      @redises.multi
      @string = 'mock-redis-test:string'
      @list = 'mock-redis-test:list'
    end

    it "makes commands respond with 'QUEUED'" do
      @redises.set(@string, 'string').should eq 'QUEUED'
      @redises.lpush(@list, 'list').should eq 'QUEUED'
    end

    it "gives you the commands' responses when you call #exec" do
      @redises.set(@string, 'string')
      @redises.lpush(@list, 'list')
      @redises.lpush(@list, 'list')

      @redises.exec.should eq ['OK', 1, 2]
    end

    it "does not raise exceptions, but rather puts them in #exec's response" do
      @redises.set(@string, 'string')
      @redises.lpush(@string, 'oops!')
      @redises.lpush(@list, 'list')

      responses = @redises.exec
      responses[0].should eq 'OK'
      responses[1].should be_a(Redis::CommandError)
      responses[2].should eq 1
    end
  end

  context 'saving commands with multi block' do
    before(:each) do
      @string = 'mock-redis-test:string'
      @list = 'mock-redis-test:list'
    end

    it 'commands return response after exec is called' do
      set_response = nil
      lpush_response = nil
      second_lpush_response = nil

      @redises.multi do |mult|
        set_response = mult.set(@string, 'string')
        lpush_response = mult.lpush(@list, 'list')
        second_lpush_response = mult.lpush(@list, 'list')
      end

      set_response.value.should eq 'OK'
      lpush_response.value.should eq 1
      second_lpush_response.value.should eq 2
    end
  end
end
