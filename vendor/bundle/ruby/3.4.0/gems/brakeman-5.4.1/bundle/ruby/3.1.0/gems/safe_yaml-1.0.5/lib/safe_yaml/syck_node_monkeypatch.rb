# This is, admittedly, pretty insane. Fundamentally the challenge here is this: if we want to allow
# whitelisting of tags (while still leveraging Syck's internal functionality), then we have to
# change how Syck::Node#transform works. But since we (SafeYAML) do not control instantiation of
# Syck::Node objects, we cannot, for example, subclass Syck::Node and override #tranform the "easy"
# way. So the only choice is to monkeypatch, like this. And the only way to make this work
# recursively with potentially call-specific options (that my feeble brain can think of) is to set
# pseudo-global options on the first call and unset them once the recursive stack has fully unwound.

monkeypatch = <<-EORUBY
  class Node
    @@safe_transform_depth     = 0
    @@safe_transform_whitelist = nil

    def safe_transform(options={})
      begin
        @@safe_transform_depth += 1
        @@safe_transform_whitelist ||= options[:whitelisted_tags]

        if self.type_id
          SafeYAML.tag_safety_check!(self.type_id, options)
          return unsafe_transform if @@safe_transform_whitelist.include?(self.type_id)
        end

        SafeYAML::SyckResolver.new.resolve_node(self)

      ensure
        @@safe_transform_depth -= 1
        if @@safe_transform_depth == 0
          @@safe_transform_whitelist = nil
        end
      end
    end

    alias_method :unsafe_transform, :transform
    alias_method :transform, :safe_transform
  end
EORUBY

if defined?(YAML::Syck::Node)
  YAML::Syck.module_eval monkeypatch
else
  Syck.module_eval monkeypatch
end
