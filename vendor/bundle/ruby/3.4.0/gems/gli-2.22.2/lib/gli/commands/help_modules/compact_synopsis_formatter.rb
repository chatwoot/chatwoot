module GLI
  module Commands
    module HelpModules
      class CompactSynopsisFormatter < FullSynopsisFormatter

      protected

        def sub_options_doc(sub_options)
          if sub_options.empty?
            ''
          else
            '[subcommand options]'
          end
        end


      end
    end
  end
end
