# frozen_string_literal: true

module AnnotateRb
  module Commands
    autoload :PrintVersion, "annotate_rb/commands/print_version"
    autoload :PrintHelp, "annotate_rb/commands/print_help"
    autoload :AnnotateModels, "annotate_rb/commands/annotate_models"
    autoload :AnnotateRoutes, "annotate_rb/commands/annotate_routes"
  end
end
