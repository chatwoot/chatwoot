def using_sqlite?
  ActsAsTaggableOn::Utils.connection && ActsAsTaggableOn::Utils.connection.adapter_name == 'SQLite'
end

def supports_concurrency?
  !using_sqlite?
end

def using_postgresql?
  ActsAsTaggableOn::Utils.using_postgresql?
end

def postgresql_version
  if using_postgresql?
    ActsAsTaggableOn::Utils.connection.execute('SHOW SERVER_VERSION').first['server_version'].to_f
  else
    0.0
  end
end

def postgresql_support_json?
  postgresql_version >= 9.2
end


def using_mysql?
  ActsAsTaggableOn::Utils.using_mysql?
end

def using_case_insensitive_collation?
  using_mysql? && ActsAsTaggableOn::Utils.connection.collation =~ /_ci\Z/
end
