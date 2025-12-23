# The contents of this file are subject to the terms
# of the Common Development and Distribution License
# (the License). You may not use this file except in
# compliance with the License.
#
# You can obtain a copy of the License at
# https://opensso.dev.java.net/public/CDDLv1.0.html or
# opensso/legal/CDDLv1.0.txt
# See the License for the specific language governing
# permission and limitations under the License.
#
# When distributing Covered Code, include this CDDL
# Header Notice in each file and include the License file
# at opensso/legal/CDDLv1.0.txt.
# If applicable, add the following below the CDDL Header,
# with the fields enclosed by brackets [] replaced by
# your own identifying information:
# "Portions Copyrighted [year] [name of copyright owner]"
#
# $Id: xml_sec.rb,v 1.6 2007/10/24 00:28:41 todddd Exp $
#
# Copyright 2007 Sun Microsystems Inc. All Rights Reserved
# Portions Copyrighted 2007 Todd W Saxton.

require 'rubygems'
require "rexml/document"
require "rexml/xpath"
require "openssl"
require 'nokogiri'
require "digest/sha1"
require "digest/sha2"
require "onelogin/ruby-saml/utils"
require "onelogin/ruby-saml/error_handling"

module XMLSecurity

  class BaseDocument < REXML::Document
    REXML::Document::entity_expansion_limit = 0

    C14N            = "http://www.w3.org/2001/10/xml-exc-c14n#"
    DSIG            = "http://www.w3.org/2000/09/xmldsig#"
    NOKOGIRI_OPTIONS = Nokogiri::XML::ParseOptions::STRICT |
                       Nokogiri::XML::ParseOptions::NONET

    # Safety load the SAML Message XML
    # @param document [REXML::Document] The message to be loaded
    # @param check_malformed_doc [Boolean] check_malformed_doc Enable or Disable the check for malformed XML
    # @return [Nokogiri::XML] The nokogiri document
    # @raise [ValidationError] If there was a problem loading the SAML Message XML
    def self.safe_load_xml(document, check_malformed_doc = true)
      doc_str = document.to_s
      if doc_str.include?("<!DOCTYPE")
       raise StandardError.new("Dangerous XML detected. No Doctype nodes allowed")
      end

      begin
        xml = Nokogiri::XML(doc_str) do |config|
          config.options = self::NOKOGIRI_OPTIONS
        end
      rescue StandardError => error
        raise StandardError.new(error.message)
      end

      if xml.internal_subset
        raise StandardError.new("Dangerous XML detected. No Doctype nodes allowed")
      end

      unless xml.errors.empty?
        raise StandardError.new("There were XML errors when parsing: #{xml.errors}") if check_malformed_doc
      end

      xml
    end

    def canon_algorithm(element)
      algorithm = element
      if algorithm.is_a?(REXML::Element)
        algorithm = element.attribute('Algorithm').value
      end

      case algorithm
        when "http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
             "http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"
          Nokogiri::XML::XML_C14N_1_0
        when "http://www.w3.org/2006/12/xml-c14n11",
             "http://www.w3.org/2006/12/xml-c14n11#WithComments"
          Nokogiri::XML::XML_C14N_1_1
        else
          Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
      end
    end

    def algorithm(element)
      algorithm = element
      if algorithm.is_a?(REXML::Element)
        algorithm = element.attribute("Algorithm").value
      end

      algorithm = algorithm && algorithm =~ /(rsa-)?sha(.*?)$/i && $2.to_i

      case algorithm
      when 256 then OpenSSL::Digest::SHA256
      when 384 then OpenSSL::Digest::SHA384
      when 512 then OpenSSL::Digest::SHA512
      else
        OpenSSL::Digest::SHA1
      end
    end

  end

  class Document < BaseDocument
    RSA_SHA1        = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    RSA_SHA256      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    RSA_SHA384      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
    RSA_SHA512      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"
    SHA1            = "http://www.w3.org/2000/09/xmldsig#sha1"
    SHA256          = 'http://www.w3.org/2001/04/xmlenc#sha256'
    SHA384          = "http://www.w3.org/2001/04/xmldsig-more#sha384"
    SHA512          = 'http://www.w3.org/2001/04/xmlenc#sha512'
    ENVELOPED_SIG   = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
    INC_PREFIX_LIST = "#default samlp saml ds xs xsi md"

    attr_writer :uuid

    def uuid
      @uuid ||= begin
        document.root.nil? ? nil : document.root.attributes['ID']
      end
    end

    #<Signature>
      #<SignedInfo>
        #<CanonicalizationMethod />
        #<SignatureMethod />
        #<Reference>
           #<Transforms>
           #<DigestMethod>
           #<DigestValue>
        #</Reference>
        #<Reference /> etc.
      #</SignedInfo>
      #<SignatureValue />
      #<KeyInfo />
      #<Object />
    #</Signature>
    def sign_document(private_key, certificate, signature_method = RSA_SHA1, digest_method = SHA1, check_malformed_doc = true)
      noko = XMLSecurity::BaseDocument.safe_load_xml(self.to_s, check_malformed_doc)

      signature_element = REXML::Element.new("ds:Signature").add_namespace('ds', DSIG)
      signed_info_element = signature_element.add_element("ds:SignedInfo")
      signed_info_element.add_element("ds:CanonicalizationMethod", {"Algorithm" => C14N})
      signed_info_element.add_element("ds:SignatureMethod", {"Algorithm"=>signature_method})

      # Add Reference
      reference_element = signed_info_element.add_element("ds:Reference", {"URI" => "##{uuid}"})

      # Add Transforms
      transforms_element = reference_element.add_element("ds:Transforms")
      transforms_element.add_element("ds:Transform", {"Algorithm" => ENVELOPED_SIG})
      c14element = transforms_element.add_element("ds:Transform", {"Algorithm" => C14N})
      c14element.add_element("ec:InclusiveNamespaces", {"xmlns:ec" => C14N, "PrefixList" => INC_PREFIX_LIST})

      digest_method_element = reference_element.add_element("ds:DigestMethod", {"Algorithm" => digest_method})
      inclusive_namespaces = INC_PREFIX_LIST.split(" ")
      canon_doc = noko.canonicalize(canon_algorithm(C14N), inclusive_namespaces)
      reference_element.add_element("ds:DigestValue").text = compute_digest(canon_doc, algorithm(digest_method_element))

      # add SignatureValue
      noko_sig_element = XMLSecurity::BaseDocument.safe_load_xml(signature_element.to_s, check_malformed_doc)

      noko_signed_info_element = noko_sig_element.at_xpath('//ds:Signature/ds:SignedInfo', 'ds' => DSIG)
      canon_string = noko_signed_info_element.canonicalize(canon_algorithm(C14N))

      signature = compute_signature(private_key, algorithm(signature_method).new, canon_string)
      signature_element.add_element("ds:SignatureValue").text = signature

      # add KeyInfo
      key_info_element       = signature_element.add_element("ds:KeyInfo")
      x509_element           = key_info_element.add_element("ds:X509Data")
      x509_cert_element      = x509_element.add_element("ds:X509Certificate")
      if certificate.is_a?(String)
        certificate = OpenSSL::X509::Certificate.new(certificate)
      end
      x509_cert_element.text = Base64.encode64(certificate.to_der).gsub(/\n/, "")

      # add the signature
      issuer_element = elements["//saml:Issuer"]
      if issuer_element
        root.insert_after(issuer_element, signature_element)
      elsif first_child = root.children[0]
        root.insert_before(first_child, signature_element)
      else
        root.add_element(signature_element)
      end
    end

    protected

    def compute_signature(private_key, signature_algorithm, document)
      Base64.encode64(private_key.sign(signature_algorithm, document)).gsub(/\n/, "")
    end

    def compute_digest(document, digest_algorithm)
      digest = digest_algorithm.digest(document)
      Base64.encode64(digest).strip
    end

  end

  class SignedDocument < BaseDocument
    include OneLogin::RubySaml::ErrorHandling

    attr_writer :signed_element_id

    def initialize(response, errors = [])
      super(response)
      @errors = errors
      reset_elements
    end

    def reset_elements
      @referenced_xml = nil
      @cached_signed_info = nil
      @signature = nil
      @signature_algorithm = nil
      @ref = nil
      @processed = false
    end

    def processed
      @processed
    end

    def referenced_xml
      @referenced_xml
    end

    def signed_element_id
      @signed_element_id ||= extract_signed_element_id
    end

    # Validates the referenced_xml, which is the signed part of the document
    def validate_document(idp_cert_fingerprint, soft = true, options = {})
      # get cert from response
      cert_element = REXML::XPath.first(
        self,
        "//ds:X509Certificate",
        { "ds"=>DSIG }
      )

      if cert_element
        base64_cert = OneLogin::RubySaml::Utils.element_text(cert_element)
        cert_text = Base64.decode64(base64_cert)
        begin
          cert = OpenSSL::X509::Certificate.new(cert_text)
        rescue OpenSSL::X509::CertificateError => _e
          return append_error("Document Certificate Error", soft)
        end

        if options[:fingerprint_alg]
          fingerprint_alg = XMLSecurity::BaseDocument.new.algorithm(options[:fingerprint_alg]).new
        else
          fingerprint_alg = OpenSSL::Digest.new('SHA1')
        end
        fingerprint = fingerprint_alg.hexdigest(cert.to_der)

        # check cert matches registered idp cert
        if fingerprint != idp_cert_fingerprint.gsub(/[^a-zA-Z0-9]/,"").downcase
          return append_error("Fingerprint mismatch", soft)
        end
        base64_cert = Base64.encode64(cert.to_der)
      else
        if options[:cert]
          base64_cert = Base64.encode64(options[:cert].to_pem)
        else
          if soft
            return false
          else
            return append_error("Certificate element missing in response (ds:X509Certificate) and not cert provided at settings", soft)
          end
        end
      end
      validate_signature(base64_cert, soft)
    end

    def validate_document_with_cert(idp_cert, soft = true)
      # get cert from response
      cert_element = REXML::XPath.first(
        self,
        "//ds:X509Certificate",
        { "ds"=>DSIG }
      )

      if cert_element
        base64_cert = OneLogin::RubySaml::Utils.element_text(cert_element)
        cert_text = Base64.decode64(base64_cert)
        begin
          cert = OpenSSL::X509::Certificate.new(cert_text)
        rescue OpenSSL::X509::CertificateError => _e
          return append_error("Document Certificate Error", soft)
        end

        # check saml response cert matches provided idp cert
        if idp_cert.to_pem != cert.to_pem
          return append_error("Certificate of the Signature element does not match provided certificate", soft)
        end
      end

      encoded_idp_cert = Base64.encode64(idp_cert.to_pem)
      validate_signature(encoded_idp_cert, true)
    end

    def cache_referenced_xml(soft, check_malformed_doc = true)
      reset_elements
      @processed = true

      begin
        nokogiri_document = XMLSecurity::BaseDocument.safe_load_xml(self, check_malformed_doc)
      rescue StandardError => error
        @errors << error.message
        return false if soft
        raise ValidationError.new("XML load failed: #{error.message}")
      end

      # create a rexml document
      @working_copy ||= REXML::Document.new(self.to_s).root

      # get signature node
      sig_element = REXML::XPath.first(
          @working_copy,
          "//ds:Signature",
          {"ds"=>DSIG}
      )

      return if sig_element.nil?

      # signature method
      sig_alg_value = REXML::XPath.first(
        sig_element,
        "./ds:SignedInfo/ds:SignatureMethod",
        {"ds"=>DSIG}
      )
      @signature_algorithm = algorithm(sig_alg_value)

      # get signature
      base64_signature = REXML::XPath.first(
        sig_element,
        "./ds:SignatureValue",
        {"ds" => DSIG}
      )

      return if base64_signature.nil?

      base64_signature_text = OneLogin::RubySaml::Utils.element_text(base64_signature)
      @signature = base64_signature_text.nil? ? nil : Base64.decode64(base64_signature_text)

      # canonicalization method
      canon_algorithm = canon_algorithm REXML::XPath.first(
        sig_element,
        './ds:SignedInfo/ds:CanonicalizationMethod',
        'ds' => DSIG
      )

      noko_sig_element = nokogiri_document.at_xpath('//ds:Signature', 'ds' => DSIG)
      noko_signed_info_element = noko_sig_element.at_xpath('./ds:SignedInfo', 'ds' => DSIG)

      @cached_signed_info = noko_signed_info_element.canonicalize(canon_algorithm)

      ### Now get the @referenced_xml to use?
      rexml_signed_info = REXML::Document.new(@cached_signed_info.to_s).root

      noko_sig_element.remove

      # get inclusive namespaces
      inclusive_namespaces = extract_inclusive_namespaces

      # check digests
      @ref = REXML::XPath.first(rexml_signed_info, "./ds:Reference", {"ds"=>DSIG})
      return if @ref.nil?

      reference_nodes = nokogiri_document.xpath("//*[@ID=$id]", nil, { 'id' => extract_signed_element_id })

      hashed_element = reference_nodes[0]
      return if hashed_element.nil?

      canon_algorithm = canon_algorithm REXML::XPath.first(
        rexml_signed_info,
        './ds:CanonicalizationMethod',
        { "ds" => DSIG }
      )

      canon_algorithm = process_transforms(@ref, canon_algorithm)

      @referenced_xml = hashed_element.canonicalize(canon_algorithm, inclusive_namespaces)
    end

    def validate_signature(base64_cert, soft = true)
      if !@processed
        cache_referenced_xml(soft)
      end

      return append_error("No Signature Algorithm Method found", soft) if @signature_algorithm.nil?  
      return append_error("No Signature node found", soft) if @signature.nil?  
      return append_error("No canonized SignedInfo ", soft) if @cached_signed_info.nil?
      return append_error("No Reference node found", soft) if @ref.nil?
      return append_error("No referenced XML", soft) if @referenced_xml.nil?

      # get certificate object
      cert_text = Base64.decode64(base64_cert)
      cert = OpenSSL::X509::Certificate.new(cert_text)

      digest_algorithm = algorithm(REXML::XPath.first(
        @ref,
        "./ds:DigestMethod",
        { "ds" => DSIG }
      ))
      hash = digest_algorithm.digest(@referenced_xml)
      encoded_digest_value = REXML::XPath.first(
        @ref,
        "./ds:DigestValue",
        { "ds" => DSIG }
      )
      encoded_digest_value_text = OneLogin::RubySaml::Utils.element_text(encoded_digest_value)
      digest_value = encoded_digest_value_text.nil? ? nil : Base64.decode64(encoded_digest_value_text)

      # Compare the computed "hash" with the "signed" hash
      unless hash && hash == digest_value
        return append_error("Digest mismatch", soft)
      end

      # verify signature
      unless cert.public_key.verify(@signature_algorithm.new, @signature, @cached_signed_info)
        return append_error("Key validation error", soft)
      end

      return true
    end

    private

    def process_transforms(ref, canon_algorithm)
      transforms = REXML::XPath.match(
        ref,
        "./ds:Transforms/ds:Transform",
        { "ds" => DSIG }
      )

      transforms.each do |transform_element|
        if transform_element.attributes && transform_element.attributes["Algorithm"]
          algorithm = transform_element.attributes["Algorithm"]
          case algorithm
            when "http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
                 "http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"
              canon_algorithm = Nokogiri::XML::XML_C14N_1_0
            when "http://www.w3.org/2006/12/xml-c14n11",
                 "http://www.w3.org/2006/12/xml-c14n11#WithComments"
              canon_algorithm = Nokogiri::XML::XML_C14N_1_1
            when "http://www.w3.org/2001/10/xml-exc-c14n#",
                 "http://www.w3.org/2001/10/xml-exc-c14n#WithComments"
              canon_algorithm = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
          end
        end
      end

      canon_algorithm
    end

    def digests_match?(hash, digest_value)
      hash == digest_value
    end

    def extract_signed_element_id
      reference_element = REXML::XPath.first(
        self,
        "//ds:Signature/ds:SignedInfo/ds:Reference",
        {"ds"=>DSIG}
      )

      return nil if reference_element.nil?

      sei = reference_element.attribute("URI").value[1..-1]
      sei.nil? ? reference_element.parent.parent.parent.attribute("ID").value : sei
    end

    def extract_inclusive_namespaces
      element = REXML::XPath.first(
        self,
        "//ec:InclusiveNamespaces",
        { "ec" => C14N }
      )
      if element
        prefix_list = element.attributes.get_attribute("PrefixList").value
        prefix_list.split(" ")
      else
        nil
      end
    end

  end
end
