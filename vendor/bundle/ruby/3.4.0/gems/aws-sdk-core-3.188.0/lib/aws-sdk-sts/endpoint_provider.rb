# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  class EndpointProvider
    def resolve_endpoint(parameters)
      region = parameters.region
      use_dual_stack = parameters.use_dual_stack
      use_fips = parameters.use_fips
      endpoint = parameters.endpoint
      use_global_endpoint = parameters.use_global_endpoint
      if Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.set?(region) && (partition_result = Aws::Endpoints::Matchers.aws_partition(region)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false)
        if Aws::Endpoints::Matchers.string_equals?(region, "ap-northeast-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "ap-south-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "ap-southeast-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "ap-southeast-2")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "ca-central-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "eu-central-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "eu-north-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "eu-west-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "eu-west-2")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "eu-west-3")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "sa-east-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "us-east-2")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "us-west-1")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        if Aws::Endpoints::Matchers.string_equals?(region, "us-west-2")
          return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
        end
        return Aws::Endpoints::Endpoint.new(url: "https://sts.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"#{region}"}]})
      end
      if Aws::Endpoints::Matchers.set?(endpoint)
        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
          raise ArgumentError, "Invalid Configuration: FIPS and custom endpoint are not supported"
        end
        if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
          raise ArgumentError, "Invalid Configuration: Dualstack and custom endpoint are not supported"
        end
        return Aws::Endpoints::Endpoint.new(url: endpoint, headers: {}, properties: {})
      end
      if Aws::Endpoints::Matchers.set?(region)
        if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
          if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
            if Aws::Endpoints::Matchers.boolean_equals?(true, Aws::Endpoints::Matchers.attr(partition_result, "supportsFIPS")) && Aws::Endpoints::Matchers.boolean_equals?(true, Aws::Endpoints::Matchers.attr(partition_result, "supportsDualStack"))
              return Aws::Endpoints::Endpoint.new(url: "https://sts-fips.#{region}.#{partition_result['dualStackDnsSuffix']}", headers: {}, properties: {})
            end
            raise ArgumentError, "FIPS and DualStack are enabled, but this partition does not support one or both"
          end
          if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
            if Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(partition_result, "supportsFIPS"), true)
              if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(partition_result, "name"), "aws-us-gov")
                return Aws::Endpoints::Endpoint.new(url: "https://sts.#{region}.amazonaws.com", headers: {}, properties: {})
              end
              return Aws::Endpoints::Endpoint.new(url: "https://sts-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {})
            end
            raise ArgumentError, "FIPS is enabled but this partition does not support FIPS"
          end
          if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
            if Aws::Endpoints::Matchers.boolean_equals?(true, Aws::Endpoints::Matchers.attr(partition_result, "supportsDualStack"))
              return Aws::Endpoints::Endpoint.new(url: "https://sts.#{region}.#{partition_result['dualStackDnsSuffix']}", headers: {}, properties: {})
            end
            raise ArgumentError, "DualStack is enabled but this partition does not support DualStack"
          end
          if Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
            return Aws::Endpoints::Endpoint.new(url: "https://sts.amazonaws.com", headers: {}, properties: {"authSchemes"=>[{"name"=>"sigv4", "signingName"=>"sts", "signingRegion"=>"us-east-1"}]})
          end
          return Aws::Endpoints::Endpoint.new(url: "https://sts.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {})
        end
      end
      raise ArgumentError, "Invalid Configuration: Missing Region"
      raise ArgumentError, 'No endpoint could be resolved'

    end
  end
end
