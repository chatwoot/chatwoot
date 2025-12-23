module Representable
  Getter = ->(input, options) do
    options[:binding].evaluate_option(:getter, input, options)
  end

  GetValue = ->(_input, options) { options[:binding].send(:exec_context, options).public_send(options[:binding].getter) }

  Writer = ->(input, options) do
    options[:binding].evaluate_option(:writer, input, options)
    Pipeline::Stop
  end

  # TODO: evaluate this, if we need this.
  RenderDefault = ->(input, options) do
    binding = options[:binding]

    binding.skipable_empty_value?(input) ? binding[:default] : input
  end

  StopOnSkipable = ->(input, options) do
    options[:binding].send(:skipable_empty_value?, input) ? Pipeline::Stop : input
  end

  RenderFilter = ->(input, options) do
    options[:binding][:render_filter].(input, options)
  end

  SkipRender = ->(input, options) do
    options[:binding].evaluate_option(:skip_render, input, options) ? Pipeline::Stop : input
  end

  Serializer = ->(input, options) do
    return if input.nil? # DISCUSS: how can we prevent that?

    options[:binding].evaluate_option(:serialize, input, options)
  end

  Serialize = ->(input, options) do
    return if input.nil? # DISCUSS: how can we prevent that?

    binding, options = options[:binding], options[:options] # FIXME: rename to :local_options.

    options_for_nested = OptionsForNested.(options, binding)

    input.send(binding.serialize_method, options_for_nested)
  end

  WriteFragment = ->(input, options) { options[:binding].write(options[:doc], input, options[:as]) }

  As = ->(input, options) { options[:binding].evaluate_option(:as, input, options) }

  # Warning: don't rely on AssignAs/AssignName, i am not sure if i leave that as functions.
  AssignAs   = ->(input, options) { options[:as] = As.(input, options); input }
  AssignName = ->(input, options) { options[:as] = options[:binding].name; input }
end
