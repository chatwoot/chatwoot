class AddCustomAttributesForTicket < ActiveRecord::Migration[7.0]
  def change
    [1, 3].each do |account_id|
      account = Account.find_by(id: account_id)

      if account
        definition = {
          attribute_display_name: "Issue Type",
          attribute_key: "issue_type",
          attribute_display_type: "list",
          default_value: nil,
          attribute_model: "conversation_attribute",
          account_id: account.id,
          attribute_description: "Ticket Issue type",
          attribute_values: ["Feedback", "Question", "2nd Line Support"],
          regex_pattern: nil,
          regex_cue: nil
        }
        
        cad = CustomAttributeDefinition.find_by(attribute_key: 'issue_type')
        
        unless cad.present?
          CustomAttributeDefinition.create(definition)
        end

        cad2 = CustomAttributeDefinition.find_by(attribute_key: 'response_needed')

        cad2_definition = {
          attribute_display_name: "Response Needed",
          attribute_key: "response_needed",
          attribute_display_type: "checkbox",
          default_value: nil,
          attribute_model: "conversation_attribute",
          account_id: account.id,
          attribute_description: "Response Needed",
          attribute_values: [],
          regex_pattern: nil,
          regex_cue: nil
        }

        unless cad2.present?
          CustomAttributeDefinition.create(cad2_definition)
        end

        cad3 = CustomAttributeDefinition.find_by(attribute_key: CustomAttributeDefinition::CONTACT_TYPE)

        cad3_definition = {
          attribute_display_name: "Contact Type",
          attribute_key: CustomAttributeDefinition::CONTACT_TYPE,
          attribute_display_type: "list",
          default_value: nil,
          attribute_model: "conversation_attribute",
          account_id: account.id,
          attribute_description: "Contact type",
          attribute_values: Digitaltolk::ChangeContactKindService::KIND_LABELS.values.map{|opt| opt.gsub('_contact', '').capitalize},
          regex_pattern: nil,
          regex_cue: nil
        }

        unless cad3.present?
          CustomAttributeDefinition.create(cad3_definition)
        end
      end
    end
  end
end
