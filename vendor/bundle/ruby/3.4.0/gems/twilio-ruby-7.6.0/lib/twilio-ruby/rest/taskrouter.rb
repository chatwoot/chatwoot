module Twilio
  module REST
    class Taskrouter < TaskrouterBase
      ##
      # @param [String] sid The unique string that we created to identify the Workspace
      #   resource.
      # @return [Twilio::REST::Taskrouter::V1::WorkspaceInstance] if sid was passed.
      # @return [Twilio::REST::Taskrouter::V1::WorkspaceList]
      def workspaces(sid=:unset)
        warn "workspaces is deprecated. Use v1.workspaces instead."
        self.v1.workspaces(sid)
      end
    end
  end
end