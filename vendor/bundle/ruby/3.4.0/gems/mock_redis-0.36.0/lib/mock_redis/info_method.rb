class MockRedis
  module InfoMethod
    SERVER_INFO = {
      'arch_bits' => '64',
      'gcc_version' => '4.2.1',
      'lru_clock' => '1036434',
      'multiplexing_api' => 'kqueue',
      'os' => 'Darwin 12.2.1 x86_64',
      'process_id' => '14508',
      'redis_git_dirty' => '0',
      'redis_git_sha1' => '00000000',
      'redis_mode' => 'standalone',
      'redis_version' => '2.6.10',
      'run_id' => '1f3f7af2fc11eb68011eb43e154adce125c85e9a',
      'tcp_port' => '6379',
      'uptime_in_days' => '0',
      'uptime_in_seconds' => '84215',
    }.freeze

    CLIENTS_INFO = {
      'blocked_clients' => '0',
      'client_biggest_input_buf' => '0',
      'client_longest_output_list' => '0',
      'connected_clients' => '1',
    }.freeze

    MEMORY_INFO = {
      'mem_allocator' => 'libc',
      'mem_fragmentation_ratio' => '2.04',
      'used_memory' => '931456',
      'used_memory_human' => '909.62K',
      'used_memory_lua' => '31744',
      'used_memory_peak' => '1005424',
      'used_memory_peak_human' => '981.86K',
      'used_memory_rss' => '1904640',
    }.freeze

    PERSISTENCE_INFO = {
      'aof_current_rewrite_time_sec' => '-1',
      'aof_enabled' => '0',
      'aof_last_bgrewrite_status' => 'ok',
      'aof_last_rewrite_time_sec' => '-1',
      'aof_rewrite_in_progress' => '0',
      'aof_rewrite_scheduled' => '0',
      'loading' => '0',
      'rdb_bgsave_in_progress' => '0',
      'rdb_changes_since_last_save' => '0',
      'rdb_current_bgsave_time_sec' => '-1',
      'rdb_last_bgsave_status' => 'ok',
      'rdb_last_bgsave_time_sec' => '-1',
      'rdb_last_save_time' => '1361423635',
    }.freeze

    STATS_INFO = {
      'evicted_keys' => '0',
      'expired_keys' => '0',
      'instantaneous_ops_per_sec' => '0',
      'keyspace_hits' => '62645',
      'keyspace_misses' => '29757',
      'latest_fork_usec' => '0',
      'pubsub_channels' => '0',
      'pubsub_patterns' => '0',
      'rejected_connections' => '0',
      'total_commands_processed' => '196800',
      'total_connections_received' => '4359',
    }.freeze

    REPLICATION_INFO = {
      'role' => 'master',
      'connected_slaves' => '0',
    }.freeze

    CPU_INFO = {
      'used_cpu_sys' => '5.54',
      'used_cpu_sys_childrens' => '0.00',
      'used_cpu_user' => '7.65',
      'used_cpu_user_childrens' => '0.02',
    }.freeze

    KEYSPACE_INFO = {
      'db0' => 'keys=8,expires=0',
    }.freeze

    # The Ruby Redis client returns commandstats differently when it's called as
    # "INFO commandstats".
    # rubocop:disable Layout/LineLength
    COMMAND_STATS_SOLO_INFO = {
      'auth' => { 'calls' => '572501', 'usec' => '2353163', 'usec_per_call' => '4.11' },
      'client' => { 'calls' => '1', 'usec' => '80', 'usec_per_call' => '80.00' },
      'config' => { 'calls' => '4', 'usec' => '71', 'usec_per_call' => '17.75' },
      'flushall' => { 'calls' => '2097790', 'usec' => '27473940655', 'usec_per_call' => '13096.61' },
      'flushdb' => { 'calls' => '692247', 'usec' => '2235143397', 'usec_per_call' => '3228.82' },
      'get' => { 'calls' => '185724', 'usec' => '604479', 'usec_per_call' => '3.25' },
      'info' => { 'calls' => '965566', 'usec' => '229377331', 'usec_per_call' => '237.56' },
      'keys' => { 'calls' => '16591', 'usec' => '917676', 'usec_per_call' => '55.31' },
      'llen' => { 'calls' => '39', 'usec' => '150', 'usec_per_call' => '3.85' },
      'ping' => { 'calls' => '697509', 'usec' => '3836044', 'usec_per_call' => '5.50' },
      'rpush' => { 'calls' => '2239810', 'usec' => '15013298', 'usec_per_call' => '6.70' },
      'sadd' => { 'calls' => '13950129156', 'usec' => '30126628979', 'usec_per_call' => '2.16' },
      'scard' => { 'calls' => '153929', 'usec' => '726596', 'usec_per_call' => '4.72' },
      'set' => { 'calls' => '6975081982', 'usec' => '16453671451', 'usec_per_call' => '2.36' },
      'slowlog' => { 'calls' => '136', 'usec' => '16815', 'usec_per_call' => '123.64' },
      'smembers' => { 'calls' => '58', 'usec' => '231', 'usec_per_call' => '3.98' },
      'sunionstore' => { 'calls' => '4185027', 'usec' => '11762454022', 'usec_per_call' => '2810.60' },
    }.freeze

    COMMAND_STATS_COMBINED_INFO = {
      'cmdstat_auth' => 'calls=572506,usec=2353182,usec_per_call=4.11',
      'cmdstat_client' => 'calls=1,usec=80,usec_per_call=80.00',
      'cmdstat_config' => 'calls=4,usec=71,usec_per_call=17.75',
      'cmdstat_flushall' => 'calls=2097790,usec=27473940655,usec_per_call=13096.61',
      'cmdstat_flushdb' => 'calls=692247,usec=2235143397,usec_per_call=3228.82',
      'cmdstat_get' => 'calls=185724,usec=604479,usec_per_call=3.25',
      'cmdstat_info' => 'calls=965571,usec=229378327,usec_per_call=237.56',
      'cmdstat_keys' => 'calls=16591,usec=917676,usec_per_call=55.31',
      'cmdstat_llen' => 'calls=39,usec=150,usec_per_call=3.85',
      'cmdstat_ping' => 'calls=697509,usec=3836044,usec_per_call=5.50',
      'cmdstat_rpush' => 'calls=2239810,usec=15013298,usec_per_call=6.70',
      'cmdstat_sadd' => 'calls=13950129156,usec=30126628979,usec_per_call=2.16',
      'cmdstat_scard' => 'calls=153929,usec=726596,usec_per_call=4.72',
      'cmdstat_set' => 'calls=6975081982,usec=16453671451,usec_per_call=2.36',
      'cmdstat_slowlog' => 'calls=136,usec=16815,usec_per_call=123.64',
      'cmdstat_smembers' => 'calls=58,usec=231,usec_per_call=3.98',
      'cmdstat_sunionstore' => 'calls=4185027,usec=11762454022,usec_per_call=2810.60',
    }.freeze
    # rubocop:enable Layout/LineLength

    DEFAULT_INFO = [
      SERVER_INFO,
      CLIENTS_INFO,
      MEMORY_INFO,
      PERSISTENCE_INFO,
      STATS_INFO,
      REPLICATION_INFO,
      CPU_INFO,
      KEYSPACE_INFO,
    ].inject({}) { |memo, info| memo.merge(info) }

    ALL_INFO = [
      DEFAULT_INFO,
      COMMAND_STATS_COMBINED_INFO,
    ].inject({}) { |memo, info| memo.merge(info) }

    def info(section = :default)
      case section
      when :default;      DEFAULT_INFO
      when :all;          ALL_INFO
      when :server;       SERVER_INFO
      when :clients;      CLIENTS_INFO
      when :memory;       MEMORY_INFO
      when :persistence;  PERSISTENCE_INFO
      when :stats;        STATS_INFO
      when :replication;  REPLICATION_INFO
      when :cpu;          CPU_INFO
      when :keyspace;     KEYSPACE_INFO
      when :commandstats; COMMAND_STATS_SOLO_INFO
      end
    end
  end
end
