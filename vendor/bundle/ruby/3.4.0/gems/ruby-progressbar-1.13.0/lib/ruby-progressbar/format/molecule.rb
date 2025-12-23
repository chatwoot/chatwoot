class   ProgressBar
module  Format
class   Molecule
  MOLECULES = {
    :t => [:title_component,      :title],
    :T => [:title_component,      :title],
    :c => [:progressable,         :progress],
    :C => [:progressable,         :total],
    :u => [:progressable,         :total_with_unknown_indicator],
    :p => [:percentage_component, :percentage],
    :P => [:percentage_component, :percentage_with_precision],
    :j => [:percentage_component, :justified_percentage],
    :J => [:percentage_component, :justified_percentage_with_precision],
    :a => [:time_component,       :elapsed_with_label],
    :e => [:time_component,       :estimated_with_unknown_oob],
    :E => [:time_component,       :estimated_with_friendly_oob],
    :f => [:time_component,       :estimated_with_no_oob],
    :l => [:time_component,       :estimated_wall_clock],
    :B => [:bar_component,        :complete_bar],
    :b => [:bar_component,        :bar],
    :W => [:bar_component,        :complete_bar_with_percentage],
    :w => [:bar_component,        :bar_with_percentage],
    :i => [:bar_component,        :incomplete_space],
    :r => [:rate_component,       :rate_of_change],
    :R => [:rate_component,       :rate_of_change_with_precision]
  }.freeze

  BAR_MOLECULES = %w{W w B b i}.freeze

  attr_accessor :key,
                :method_name

  def initialize(letter)
    self.key         = letter
    self.method_name = MOLECULES.fetch(key.to_sym)
  end

  def bar_molecule?
    BAR_MOLECULES.include? key
  end

  def non_bar_molecule?
    !bar_molecule?
  end

  def full_key
    "%#{key}"
  end

  def lookup_value(environment, length = 0)
    component = environment.__send__(method_name[0])

    if bar_molecule?
      component.__send__(method_name[1], length).to_s
    else
      component.__send__(method_name[1]).to_s
    end
  end
end
end
end
