class AddNameToTemplates < ActiveRecord::Migration[7.0]
  def change
    CsatTemplate.where(name: [nil, '']).each do |template|
      template.update(name: "Template #{template.created_at.to_s.split.first}")
    end
  end
end
