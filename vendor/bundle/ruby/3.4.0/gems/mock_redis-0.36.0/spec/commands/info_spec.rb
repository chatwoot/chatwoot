require 'spec_helper'

describe '#info [mock only]' do
  let(:redis) { @redises.mock }

  it 'responds with a config hash' do
    redis.info.should be_a(Hash)
  end

  it 'gets default set of info' do
    info = redis.info
    info['arch_bits'].should be_a(String)
    info['connected_clients'].should be_a(String)
    info['aof_rewrite_scheduled'].should be_a(String)
    info['used_cpu_sys'].should be_a(String)
  end

  it 'gets all info' do
    info = redis.info(:all)
    info['arch_bits'].should be_a(String)
    info['connected_clients'].should be_a(String)
    info['aof_rewrite_scheduled'].should be_a(String)
    info['used_cpu_sys'].should be_a(String)
    info['cmdstat_slowlog'].should be_a(String)
  end

  it 'gets server info' do
    redis.info(:server)['arch_bits'].should be_a(String)
  end

  it 'gets clients info' do
    redis.info(:clients)['connected_clients'].should be_a(String)
  end

  it 'gets memory info' do
    redis.info(:memory)['used_memory'].should be_a(String)
  end

  it 'gets persistence info' do
    redis.info(:persistence)['aof_rewrite_scheduled'].should be_a(String)
  end

  it 'gets stats info' do
    redis.info(:stats)['keyspace_hits'].should be_a(String)
  end

  it 'gets replication info' do
    redis.info(:replication)['role'].should be_a(String)
  end

  it 'gets cpu info' do
    redis.info(:cpu)['used_cpu_sys'].should be_a(String)
  end

  it 'gets keyspace info' do
    redis.info(:keyspace)['db0'].should be_a(String)
  end

  it 'gets commandstats info' do
    redis.info(:commandstats)['sunionstore']['usec'].should be_a(String)
  end
end
