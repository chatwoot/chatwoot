# frozen_string_literal: true

module Datadog
  module DI
    # Provides an interface expected by the core Remote subsystem to
    # receive DI-specific remote configuration.
    #
    # In order to apply (i.e., act on) the configuration, we need the
    # state stored under DI Component. Thus, this module forwards actual
    # configuration application to the ProbeManager associated with the
    # global DI Component.
    #
    # @api private
    module Remote
      class ReadError < StandardError; end

      class << self
        PRODUCT = 'LIVE_DEBUGGING'

        def products
          # TODO: do not send our product on unsupported runtimes
          # (Ruby 2.5 / JRuby)
          [PRODUCT]
        end

        def capabilities
          []
        end

        def receivers(telemetry)
          receiver do |repository, _changes|
            # DEV: Filter our by product. Given it will be very common
            # DEV: we can filter this out before we receive the data in this method.
            # DEV: Apply this refactor to AppSec as well if implemented.

            component = DI.component
            # We should always have a non-nil DI component here, because we
            # only add DI product to remote config request if DI is enabled.
            # Ideally, we should be injected with the DI component here
            # rather than having to retrieve it from global state.
            # If the component is nil for some reason, we also don't have a
            # logger instance to report the issue.
            if component

              probe_manager = component.probe_manager

              current_probe_ids = {}
              repository.contents.each do |content|
                case content.path.product
                when PRODUCT
                  begin
                    probe_spec = parse_content(content)
                    probe = ProbeBuilder.build_from_remote_config(probe_spec)
                    probe_notification_builder = component.probe_notification_builder
                    payload = probe_notification_builder.build_received(probe)
                    probe_notifier_worker = component.probe_notifier_worker
                    probe_notifier_worker.add_status(payload)
                    component.logger.debug { "di: received #{probe.type} probe at #{probe.location} (#{probe.id}) via RC" }

                    begin
                      # TODO test exception capture
                      probe_manager.add_probe(probe)
                      content.applied
                    rescue DI::Error::DITargetNotInRegistry => exc
                      component.telemetry&.report(exc, description: "Line probe is targeting a loaded file that is not in code tracker")

                      payload = probe_notification_builder.build_errored(probe, exc)
                      probe_notifier_worker.add_status(payload)

                      # If a probe fails to install, we will mark the content
                      # as errored. On subsequent remote configuration application
                      # attemps, probe manager will raise the "previously errored"
                      # exception and we'll rescue it here, again marking the
                      # content as errored but with a somewhat different exception
                      # message.
                      # TODO assert content state (errored for this example)
                      content.errored("Error applying dynamic instrumentation configuration: #{exc.class.name} #{exc.message}")
                    rescue => exc
                      raise if component.settings.dynamic_instrumentation.internal.propagate_all_exceptions

                      component.logger.debug { "di: unhandled exception adding #{probe.type} probe at #{probe.location} (#{probe.id}) in DI remote receiver: #{exc.class}: #{exc}" }
                      component.telemetry&.report(exc, description: "Unhandled exception adding probe in DI remote receiver")

                      # TODO test this path
                      payload = probe_notification_builder.build_errored(probe, exc)
                      probe_notifier_worker.add_status(payload)

                      # If a probe fails to install, we will mark the content
                      # as errored. On subsequent remote configuration application
                      # attemps, probe manager will raise the "previously errored"
                      # exception and we'll rescue it here, again marking the
                      # content as errored but with a somewhat different exception
                      # message.
                      # TODO assert content state (errored for this example)
                      content.errored("Error applying dynamic instrumentation configuration: #{exc.class.name} #{exc.message}")
                    end

                    # Important: even if processing fails for this probe config,
                    # we need to note it as being current so that we do not
                    # try to remove instrumentation that is still supposed to be
                    # active.
                    current_probe_ids[probe_spec.fetch('id')] = true
                  rescue => exc
                    raise if component.settings.dynamic_instrumentation.internal.propagate_all_exceptions

                    component.logger.debug { "di: unhandled exception handling a probe in DI remote receiver: #{exc.class}: #{exc}" }
                    component.telemetry&.report(exc, description: "Unhandled exception handling probe in DI remote receiver")

                    # TODO assert content state (errored for this example)
                    content.errored("Error applying dynamic instrumentation configuration: #{exc.class.name} #{exc.message}")
                  end
                end
              end

              begin
                # TODO test exception capture
                probe_manager.remove_other_probes(current_probe_ids.keys)
              rescue => exc
                raise if component.settings.dynamic_instrumentation.internal.propagate_all_exceptions

                component.logger.debug { "di: unhandled exception removing probes in DI remote receiver: #{exc.class}: #{exc}" }
                component.telemetry&.report(exc, description: "Unhandled exception removing probes in DI remote receiver")
              end
            end
          end
        end

        def receiver(products = [PRODUCT], &block)
          matcher = Core::Remote::Dispatcher::Matcher::Product.new(products)
          [Core::Remote::Dispatcher::Receiver.new(matcher, &block)]
        end

        private

        def parse_content(content)
          data = content.data.read

          content.data.rewind

          raise ReadError, 'EOF reached' if data.nil?

          JSON.parse(data)
        end
      end
    end
  end
end
