# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  class EndpointProvider
    def resolve_endpoint(parameters)
      bucket = parameters.bucket
      region = parameters.region
      use_fips = parameters.use_fips
      use_dual_stack = parameters.use_dual_stack
      endpoint = parameters.endpoint
      force_path_style = parameters.force_path_style
      accelerate = parameters.accelerate
      use_global_endpoint = parameters.use_global_endpoint
      use_object_lambda_endpoint = parameters.use_object_lambda_endpoint
      disable_access_points = parameters.disable_access_points
      disable_multi_region_access_points = parameters.disable_multi_region_access_points
      use_arn_region = parameters.use_arn_region
      if Aws::Endpoints::Matchers.set?(region)
        if Aws::Endpoints::Matchers.set?(bucket) && (hardware_type = Aws::Endpoints::Matchers.substring(bucket, 49, 50, true)) && (region_prefix = Aws::Endpoints::Matchers.substring(bucket, 8, 12, true)) && (abba_suffix = Aws::Endpoints::Matchers.substring(bucket, 0, 7, true)) && (outpost_id = Aws::Endpoints::Matchers.substring(bucket, 32, 49, true)) && (region_partition = Aws::Endpoints::Matchers.aws_partition(region)) && Aws::Endpoints::Matchers.string_equals?(abba_suffix, "--op-s3")
          if Aws::Endpoints::Matchers.valid_host_label?(outpost_id, false)
            if Aws::Endpoints::Matchers.string_equals?(hardware_type, "e")
              if Aws::Endpoints::Matchers.string_equals?(region_prefix, "beta")
                if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint))
                  raise ArgumentError, "Expected a endpoint to be specified but no endpoint was found"
                end
                if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.ec2.#{url['authority']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{region}"}]})
                end
              end
              return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.ec2.s3-outposts.#{region}.#{region_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{region}"}]})
            end
            if Aws::Endpoints::Matchers.string_equals?(hardware_type, "o")
              if Aws::Endpoints::Matchers.string_equals?(region_prefix, "beta")
                if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint))
                  raise ArgumentError, "Expected a endpoint to be specified but no endpoint was found"
                end
                if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.op-#{outpost_id}.#{url['authority']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{region}"}]})
                end
              end
              return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.op-#{outpost_id}.s3-outposts.#{region}.#{region_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{region}"}]})
            end
            raise ArgumentError, "Unrecognized hardware type: \"Expected hardware type o or e but got #{hardware_type}\""
          end
          raise ArgumentError, "Invalid ARN: The outpost Id must only contain a-z, A-Z, 0-9 and `-`."
        end
        if Aws::Endpoints::Matchers.set?(bucket)
          if Aws::Endpoints::Matchers.set?(endpoint) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(Aws::Endpoints::Matchers.parse_url(endpoint)))
            raise ArgumentError, "Custom endpoint `#{endpoint}` was not a valid URI"
          end
          if Aws::Endpoints::Matchers.set?(force_path_style) && Aws::Endpoints::Matchers.boolean_equals?(force_path_style, true)
            if Aws::Endpoints::Matchers.aws_parse_arn(bucket)
              raise ArgumentError, "Path-style addressing cannot be used with ARN buckets"
            end
            if (uri_encoded_bucket = Aws::Endpoints::Matchers.uri_encode(bucket))
              if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint)
                raise ArgumentError, "Cannot set dual-stack in combination with a custom endpoint."
              end
              if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
                if Aws::Endpoints::Matchers.boolean_equals?(accelerate, false)
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                      return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                    end
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                    if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                      return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                    end
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                end
                raise ArgumentError, "Path-style addressing cannot be used with S3 Accelerate"
              end
              raise ArgumentError, "A valid partition could not be determined"
            end
          end
          if Aws::Endpoints::Matchers.aws_virtual_hostable_s3_bucket?(bucket, false)
            if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
              if Aws::Endpoints::Matchers.valid_host_label?(region, false)
                if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(partition_result, "name"), "aws-cn")
                  raise ArgumentError, "Partition does not support FIPS"
                end
                if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                  raise ArgumentError, "Accelerate cannot be used with FIPS"
                end
                if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(partition_result, "name"), "aws-cn")
                  raise ArgumentError, "S3 Accelerate cannot be used in this region"
                end
                if Aws::Endpoints::Matchers.set?(endpoint) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                  raise ArgumentError, "Host override cannot be combined with Dualstack, FIPS, or S3 Accelerate"
                end
                if Aws::Endpoints::Matchers.set?(endpoint) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                  raise ArgumentError, "Host override cannot be combined with Dualstack, FIPS, or S3 Accelerate"
                end
                if Aws::Endpoints::Matchers.set?(endpoint) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                  raise ArgumentError, "Host override cannot be combined with Dualstack, FIPS, or S3 Accelerate"
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.dualstack.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.dualstack.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(Aws::Endpoints::Matchers.attr(url, "isIp"), false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3-accelerate.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://#{bucket}.s3.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
              end
              raise ArgumentError, "Invalid region: region was not a valid DNS name."
            end
            raise ArgumentError, "A valid partition could not be determined"
          end
          if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(url, "scheme"), "http") && Aws::Endpoints::Matchers.aws_virtual_hostable_s3_bucket?(bucket, true) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.boolean_equals?(accelerate, false)
            if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
              if Aws::Endpoints::Matchers.valid_host_label?(region, false)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{bucket}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              raise ArgumentError, "Invalid region: region was not a valid DNS name."
            end
            raise ArgumentError, "A valid partition could not be determined"
          end
          if (bucket_arn = Aws::Endpoints::Matchers.aws_parse_arn(bucket))
            if (arn_type = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[0]")) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(arn_type, ""))
              if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "service"), "s3-object-lambda")
                if Aws::Endpoints::Matchers.string_equals?(arn_type, "accesspoint")
                  if (access_point_name = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[1]")) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(access_point_name, ""))
                    if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                      raise ArgumentError, "S3 Object Lambda does not support Dual-stack"
                    end
                    if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                      raise ArgumentError, "S3 Object Lambda does not support S3 Accelerate"
                    end
                    if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), ""))
                      if Aws::Endpoints::Matchers.set?(disable_access_points) && Aws::Endpoints::Matchers.boolean_equals?(disable_access_points, true)
                        raise ArgumentError, "Access points are not supported for this operation"
                      end
                      if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[2]")))
                        if Aws::Endpoints::Matchers.set?(use_arn_region) && Aws::Endpoints::Matchers.boolean_equals?(use_arn_region, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), "#{region}"))
                          raise ArgumentError, "Invalid configuration: region from ARN `#{bucket_arn['region']}` does not match client region `#{region}` and UseArnRegion is `false`"
                        end
                        if (bucket_partition = Aws::Endpoints::Matchers.aws_partition(Aws::Endpoints::Matchers.attr(bucket_arn, "region")))
                          if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
                            if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_partition, "name"), Aws::Endpoints::Matchers.attr(partition_result, "name"))
                              if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), true)
                                if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "accountId"), "")
                                  raise ArgumentError, "Invalid ARN: Missing account id"
                                end
                                if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "accountId"), false)
                                  if Aws::Endpoints::Matchers.valid_host_label?(access_point_name, false)
                                    if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_partition, "name"), "aws-cn")
                                      raise ArgumentError, "Partition does not support FIPS"
                                    end
                                    if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                                      return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{access_point_name}-#{bucket_arn['accountId']}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                    end
                                    if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                                      return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-object-lambda-fips.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                    end
                                    return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-object-lambda.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                  end
                                  raise ArgumentError, "Invalid ARN: The access point name may only contain a-z, A-Z, 0-9 and `-`. Found: `#{access_point_name}`"
                                end
                                raise ArgumentError, "Invalid ARN: The account id may only contain a-z, A-Z, 0-9 and `-`. Found: `#{bucket_arn['accountId']}`"
                              end
                              raise ArgumentError, "Invalid region in ARN: `#{bucket_arn['region']}` (invalid DNS name)"
                            end
                            raise ArgumentError, "Client was configured for partition `#{partition_result['name']}` but ARN (`#{bucket}`) has `#{bucket_partition['name']}`"
                          end
                          raise ArgumentError, "A valid partition could not be determined"
                        end
                        raise ArgumentError, "Could not load partition for ARN region `#{bucket_arn['region']}`"
                      end
                      raise ArgumentError, "Invalid ARN: The ARN may only contain a single resource component after `accesspoint`."
                    end
                    raise ArgumentError, "Invalid ARN: bucket ARN is missing a region"
                  end
                  raise ArgumentError, "Invalid ARN: Expected a resource of the format `accesspoint:<accesspoint name>` but no name was provided"
                end
                raise ArgumentError, "Invalid ARN: Object Lambda ARNs only support `accesspoint` arn types, but found: `#{arn_type}`"
              end
              if Aws::Endpoints::Matchers.string_equals?(arn_type, "accesspoint")
                if (access_point_name = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[1]")) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(access_point_name, ""))
                  if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), ""))
                    if Aws::Endpoints::Matchers.string_equals?(arn_type, "accesspoint")
                      if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), ""))
                        if Aws::Endpoints::Matchers.set?(disable_access_points) && Aws::Endpoints::Matchers.boolean_equals?(disable_access_points, true)
                          raise ArgumentError, "Access points are not supported for this operation"
                        end
                        if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[2]")))
                          if Aws::Endpoints::Matchers.set?(use_arn_region) && Aws::Endpoints::Matchers.boolean_equals?(use_arn_region, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), "#{region}"))
                            raise ArgumentError, "Invalid configuration: region from ARN `#{bucket_arn['region']}` does not match client region `#{region}` and UseArnRegion is `false`"
                          end
                          if (bucket_partition = Aws::Endpoints::Matchers.aws_partition(Aws::Endpoints::Matchers.attr(bucket_arn, "region")))
                            if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
                              if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_partition, "name"), "#{partition_result['name']}")
                                if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), true)
                                  if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "service"), "s3")
                                    if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "accountId"), false)
                                      if Aws::Endpoints::Matchers.valid_host_label?(access_point_name, false)
                                        if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                                          raise ArgumentError, "Access Points do not support S3 Accelerate"
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_partition, "name"), "aws-cn")
                                          raise ArgumentError, "Partition does not support FIPS"
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint)
                                          raise ArgumentError, "DualStack cannot be combined with a Host override (PrivateLink)"
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                                          return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-accesspoint-fips.dualstack.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false)
                                          return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-accesspoint-fips.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                                          return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-accesspoint.dualstack.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                                          return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{access_point_name}-#{bucket_arn['accountId']}.#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                        end
                                        if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false)
                                          return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.s3-accesspoint.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                        end
                                      end
                                      raise ArgumentError, "Invalid ARN: The access point name may only contain a-z, A-Z, 0-9 and `-`. Found: `#{access_point_name}`"
                                    end
                                    raise ArgumentError, "Invalid ARN: The account id may only contain a-z, A-Z, 0-9 and `-`. Found: `#{bucket_arn['accountId']}`"
                                  end
                                  raise ArgumentError, "Invalid ARN: The ARN was not for the S3 service, found: #{bucket_arn['service']}"
                                end
                                raise ArgumentError, "Invalid region in ARN: `#{bucket_arn['region']}` (invalid DNS name)"
                              end
                              raise ArgumentError, "Client was configured for partition `#{partition_result['name']}` but ARN (`#{bucket}`) has `#{bucket_partition['name']}`"
                            end
                            raise ArgumentError, "A valid partition could not be determined"
                          end
                          raise ArgumentError, "Could not load partition for ARN region `#{bucket_arn['region']}`"
                        end
                        raise ArgumentError, "Invalid ARN: The ARN may only contain a single resource component after `accesspoint`."
                      end
                      raise ArgumentError, "Invalid ARN: bucket ARN is missing a region"
                    end
                  end
                  if Aws::Endpoints::Matchers.valid_host_label?(access_point_name, true)
                    if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                      raise ArgumentError, "S3 MRAP does not support dual-stack"
                    end
                    if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                      raise ArgumentError, "S3 MRAP does not support FIPS"
                    end
                    if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                      raise ArgumentError, "S3 MRAP does not support S3 Accelerate"
                    end
                    if Aws::Endpoints::Matchers.boolean_equals?(disable_multi_region_access_points, true)
                      raise ArgumentError, "Invalid configuration: Multi-Region Access Point ARNs are disabled."
                    end
                    if (mrap_partition = Aws::Endpoints::Matchers.aws_partition(region))
                      if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(mrap_partition, "name"), Aws::Endpoints::Matchers.attr(bucket_arn, "partition"))
                        return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}.accesspoint.s3-global.#{mrap_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4a", "signingName"=>"s3", "signingRegionSet"=>["*"]}]})
                      end
                      raise ArgumentError, "Client was configured for partition `#{mrap_partition['name']}` but bucket referred to partition `#{bucket_arn['partition']}`"
                    end
                    raise ArgumentError, "#{region} was not a valid region"
                  end
                  raise ArgumentError, "Invalid Access Point Name"
                end
                raise ArgumentError, "Invalid ARN: Expected a resource of the format `accesspoint:<accesspoint name>` but no name was provided"
              end
              if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "service"), "s3-outposts")
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                  raise ArgumentError, "S3 Outposts does not support Dual-stack"
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                  raise ArgumentError, "S3 Outposts does not support FIPS"
                end
                if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                  raise ArgumentError, "S3 Outposts does not support S3 Accelerate"
                end
                if Aws::Endpoints::Matchers.set?(Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[4]"))
                  raise ArgumentError, "Invalid Arn: Outpost Access Point ARN contains sub resources"
                end
                if (outpost_id = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[1]"))
                  if Aws::Endpoints::Matchers.valid_host_label?(outpost_id, false)
                    if Aws::Endpoints::Matchers.set?(use_arn_region) && Aws::Endpoints::Matchers.boolean_equals?(use_arn_region, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), "#{region}"))
                      raise ArgumentError, "Invalid configuration: region from ARN `#{bucket_arn['region']}` does not match client region `#{region}` and UseArnRegion is `false`"
                    end
                    if (bucket_partition = Aws::Endpoints::Matchers.aws_partition(Aws::Endpoints::Matchers.attr(bucket_arn, "region")))
                      if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
                        if Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(bucket_partition, "name"), Aws::Endpoints::Matchers.attr(partition_result, "name"))
                          if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "region"), true)
                            if Aws::Endpoints::Matchers.valid_host_label?(Aws::Endpoints::Matchers.attr(bucket_arn, "accountId"), false)
                              if (outpost_type = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[2]"))
                                if (access_point_name = Aws::Endpoints::Matchers.attr(bucket_arn, "resourceId[3]"))
                                  if Aws::Endpoints::Matchers.string_equals?(outpost_type, "accesspoint")
                                    if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                                      return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.#{outpost_id}.#{url['authority']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                    end
                                    return Aws::Endpoints::Endpoint.new(url: "https://#{access_point_name}-#{bucket_arn['accountId']}.#{outpost_id}.s3-outposts.#{bucket_arn['region']}.#{bucket_partition['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-outposts", "signingRegion"=>"#{bucket_arn['region']}"}]})
                                  end
                                  raise ArgumentError, "Expected an outpost type `accesspoint`, found #{outpost_type}"
                                end
                                raise ArgumentError, "Invalid ARN: expected an access point name"
                              end
                              raise ArgumentError, "Invalid ARN: Expected a 4-component resource"
                            end
                            raise ArgumentError, "Invalid ARN: The account id may only contain a-z, A-Z, 0-9 and `-`. Found: `#{bucket_arn['accountId']}`"
                          end
                          raise ArgumentError, "Invalid region in ARN: `#{bucket_arn['region']}` (invalid DNS name)"
                        end
                        raise ArgumentError, "Client was configured for partition `#{partition_result['name']}` but ARN (`#{bucket}`) has `#{bucket_partition['name']}`"
                      end
                      raise ArgumentError, "A valid partition could not be determined"
                    end
                    raise ArgumentError, "Could not load partition for ARN region #{bucket_arn['region']}"
                  end
                  raise ArgumentError, "Invalid ARN: The outpost Id may only contain a-z, A-Z, 0-9 and `-`. Found: `#{outpost_id}`"
                end
                raise ArgumentError, "Invalid ARN: The Outpost Id was not set"
              end
              raise ArgumentError, "Invalid ARN: Unrecognized format: #{bucket} (type: #{arn_type})"
            end
            raise ArgumentError, "Invalid ARN: No ARN type specified"
          end
          if (arn_prefix = Aws::Endpoints::Matchers.substring(bucket, 0, 4, false)) && Aws::Endpoints::Matchers.string_equals?(arn_prefix, "arn:") && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(Aws::Endpoints::Matchers.aws_parse_arn(bucket)))
            raise ArgumentError, "Invalid ARN: `#{bucket}` was not a valid ARN"
          end
          if (uri_encoded_bucket = Aws::Endpoints::Matchers.uri_encode(bucket))
            if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint)
              raise ArgumentError, "Cannot set dual-stack in combination with a custom endpoint."
            end
            if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
              if Aws::Endpoints::Matchers.boolean_equals?(accelerate, false)
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['normalizedPath']}#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                  if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                    return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                  end
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}/#{uri_encoded_bucket}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
              end
              raise ArgumentError, "Path-style addressing cannot be used with S3 Accelerate"
            end
            raise ArgumentError, "A valid partition could not be determined"
          end
        end
        if Aws::Endpoints::Matchers.set?(use_object_lambda_endpoint) && Aws::Endpoints::Matchers.boolean_equals?(use_object_lambda_endpoint, true)
          if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
            if Aws::Endpoints::Matchers.valid_host_label?(region, true)
              if Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true)
                raise ArgumentError, "S3 Object Lambda does not support Dual-stack"
              end
              if Aws::Endpoints::Matchers.boolean_equals?(accelerate, true)
                raise ArgumentError, "S3 Object Lambda does not support S3 Accelerate"
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(partition_result, "name"), "aws-cn")
                raise ArgumentError, "Partition does not support FIPS"
              end
              if Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint))
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true)
                return Aws::Endpoints::Endpoint.new(url: "https://s3-object-lambda-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{region}"}]})
              end
              return Aws::Endpoints::Endpoint.new(url: "https://s3-object-lambda.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3-object-lambda", "signingRegion"=>"#{region}"}]})
            end
            raise ArgumentError, "Invalid region: region was not a valid DNS name."
          end
          raise ArgumentError, "A valid partition could not be determined"
        end
        if Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(bucket))
          if (partition_result = Aws::Endpoints::Matchers.aws_partition(region))
            if Aws::Endpoints::Matchers.valid_host_label?(region, true)
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.string_equals?(Aws::Endpoints::Matchers.attr(partition_result, "name"), "aws-cn")
                raise ArgumentError, "Partition does not support FIPS"
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, true) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "https://s3-fips.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.us-east-1.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, true) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "https://s3.dualstack.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                  return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.set?(endpoint) && (url = Aws::Endpoints::Matchers.parse_url(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "#{url['scheme']}://#{url['authority']}#{url['path']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.string_equals?(region, "aws-global")
                return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"us-east-1"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, true)
                if Aws::Endpoints::Matchers.string_equals?(region, "us-east-1")
                  return Aws::Endpoints::Endpoint.new(url: "https://s3.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
                end
                return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
              if Aws::Endpoints::Matchers.boolean_equals?(use_fips, false) && Aws::Endpoints::Matchers.boolean_equals?(use_dual_stack, false) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.set?(endpoint)) && Aws::Endpoints::Matchers.not(Aws::Endpoints::Matchers.string_equals?(region, "aws-global")) && Aws::Endpoints::Matchers.boolean_equals?(use_global_endpoint, false)
                return Aws::Endpoints::Endpoint.new(url: "https://s3.#{region}.#{partition_result['dnsSuffix']}", headers: {}, properties: {"authSchemes"=>[{"disableDoubleEncoding"=>true, "name"=>"sigv4", "signingName"=>"s3", "signingRegion"=>"#{region}"}]})
              end
            end
            raise ArgumentError, "Invalid region: region was not a valid DNS name."
          end
          raise ArgumentError, "A valid partition could not be determined"
        end
      end
      raise ArgumentError, "A region must be set when sending requests to S3."
      raise ArgumentError, 'No endpoint could be resolved'

    end
  end
end
