require Rails.root.join('lib/read_replica')
require Rails.root.join('lib/read_replica/configuration')

ReadReplica::Configuration.validate!
