# NOTE: this might become a separate class, that's why it's in a separate file.
module Representable
  module Binding::Factories
    def pipeline_for(name, input, options)
      return yield unless (proc = @definition[name])

      # proc.(self, options)
      instance_exec(input, options, &proc)
    end

    # i decided not to use polymorphism here for the sake of clarity.
    def collect_for(item_functions)
      return [Collect[*item_functions]] if array?
      return [Collect::Hash[*item_functions]] if self[:hash]

      item_functions
    end

    def parse_functions
      [*default_parse_init_functions, *collect_for(default_parse_fragment_functions), *default_post_functions]
    end

    # DISCUSS: StopOnNil, before collect
    def render_functions
      [*default_render_init_functions, *collect_for(default_render_fragment_functions), WriteFragment]
    end

    def default_render_fragment_functions
      functions = []
      functions << SkipRender if self[:skip_render]
      if typed? # TODO: allow prepare regardless of :extend, which makes it independent of typed?
        if self[:prepare]
          functions << Prepare
        end
        # functions << (self[:prepare] ? Prepare : Decorate)
      end
      functions << Decorate if self[:extend] and !self[:prepare]
      if representable?
        functions << (self[:serialize] ? Serializer : Serialize)
      end
      functions
    end

    def default_render_init_functions
      functions = []
      functions << Stop if self[:readable]==false
      functions << StopOnExcluded
      functions << If if self[:if]
      functions << (self[:getter] ? Getter : GetValue)
      functions << Writer if self[:writer]
      functions << RenderFilter if self[:render_filter].any?
      functions << RenderDefault if has_default?
      functions << StopOnSkipable
      functions << (self[:as] ? AssignAs : AssignName)
    end

    def default_parse_init_functions
      functions = []
      functions << Stop if self[:writeable]==false
      functions << StopOnExcluded
      functions << If if self[:if]
      functions << (self[:as] ? AssignAs : AssignName)
      functions << (self[:reader] ? Reader : ReadFragment)
      functions << (has_default? ? Default : StopOnNotFound)
      functions << OverwriteOnNil # include StopOnNil if you don't want to erase things.
    end

    def default_parse_fragment_functions
      functions = [AssignFragment]
      functions << SkipParse if self[:skip_parse]

      if self[:class] or self[:extend] or self[:instance] or self[:populator]
        if self[:populator]
          functions << CreateObject::Populator
        elsif self[:parse_strategy]
          functions << CreateObject::Instance # TODO: remove in 2.5.
        else
          functions << (self[:class] ? CreateObject::Class : CreateObject::Instance)
        end

        functions << Prepare     if self[:prepare]
        functions << Decorate    if self[:extend]
        if representable?
          functions << (self[:deserialize] ? Deserializer : Deserialize)
        end
      end

      functions
    end

    def default_post_functions
      funcs = []
      funcs << ParseFilter if self[:parse_filter].any?
      funcs << (self[:setter] ? Setter : SetValue)
    end
  end
end
