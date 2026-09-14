class Captain::Apropos::Knowledge
  def self.entries
    Rails.root.join('enterprise/app/services/captain/apropos/knowledge').glob('*.md').sort.to_h do |path|
      _, frontmatter, body = path.read.split(/^---\s*$\n?/, 3)
      metadata = YAML.safe_load(frontmatter)
      name = metadata.fetch('name')
      relations = metadata.fetch('relations').transform_values do |targets|
        Array(targets).map { |target| "knowledge/#{target}" }
      end

      ["knowledge/#{name}", { kind: 'knowledge', description: metadata.fetch('description'),
                              keywords: metadata.fetch('keywords'), concept_relations: relations, markdown: body.strip }]
    end
  end
end
