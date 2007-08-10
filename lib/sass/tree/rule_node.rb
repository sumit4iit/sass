require 'sass/tree/node'
require 'sass/tree/attr_node'

module Sass::Tree
  class RuleNode < ValueNode
    # The character used to include the parent selector
    PARENT = '&'

    alias_method :rule, :value
    alias_method :rule=, :value=

    def continued?
      rule[-1] == ?,
    end
    
    def to_s(tabs, super_rules = nil)
      attributes = []
      sub_rules = []

      # Save this because the comma's removed by the super_rule additions
      was_continued = continued?

      total_rule = if super_rules
        super_rules.split(/,\s*/).collect! do |s|
          self.rule.split(/,\s*/).collect do |r|
            if r.include?(PARENT)
              r.gsub(PARENT, s)
            else
              "#{s} #{r}"
            end
          end.join(", ")
        end.join(", ") + (was_continued ? ',' : '')
      elsif self.rule.include?(PARENT)
        raise Sass::SyntaxError.new("Base-level rules cannot contain the parent-selector-referencing character '#{PARENT}'", line)
      else
        self.rule
      end
      
      children.each do |child|
        if child.is_a? RuleNode
          sub_rules << child
        else
          attributes << child
        end
      end
      
      to_return = ''
      if !attributes.empty?
        if @style == :compact
          to_return << "#{total_rule} { #{attributes.join(' ')} }\n"
        else
          spaces = (@style == :expanded ? 2 : tabs * 2)
          old_spaces = ' ' * (spaces - 2)
          spaces = ' ' * spaces

          attributes = attributes.join("\n").gsub("\n", "\n#{spaces}").rstrip
          end_attrs = (@style == :expanded ? "\n" : ' ')
          to_return << "#{old_spaces}#{total_rule} {\n#{spaces}#{attributes}#{end_attrs}}\n"
        end
      elsif continued?
        to_return << total_rule + (@style == :compact ? ' ' : "\n")
      end
      
      tabs += 1 unless attributes.empty?
      sub_rules.each do |sub|
        if sub.continued?
          check_multiline_rule(sub)
        end

        to_return << sub.to_s(tabs, total_rule)
      end
      to_return
    end
  end
end
