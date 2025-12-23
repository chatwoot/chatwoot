# Module for helping to deal with Source Code Management settings
module ScoutApm
  module Utils
    class Scm
      # Takes an *already relative* path +path+
      # Returns a relative path, prepending the configured +scm_subdirectory+ environment string
      def self.relative_scm_path(path, scm_subdirectory = ScoutApm::Agent.instance.context.environment.scm_subdirectory)
        @@scm_subdirectory ||= scm_subdirectory.sub(/^\//, '')
        @@scm_subdirectoy_blank ||= @@scm_subdirectory.empty?
        @@scm_subdirectoy_blank ? path : File.join(@@scm_subdirectory, path)
      end
    end
  end
end
