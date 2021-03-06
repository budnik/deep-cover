# frozen_string_literal: true

module DeepCover
  bootstrap
  load_parser

  class Node
    # Reopened in base
    CLASSES = []
    def self.inherited(parent)
      CLASSES << parent
      super
    end
  end
  require_relative_dir 'node/mixin'
  require_relative 'node/base'
  require_relative_dir 'node'

  Node.include Memoize
  Node::CLASSES.freeze.each do |klass|
    klass.memoize :flow_entry_count, :flow_completion_count, :execution_count, :loc_hash
  end
end
