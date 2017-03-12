# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # A single compressor-level result.
  #
  Result = Struct.new(
    :target,
    :compressor_name,
    :compressor_level,
    :time,
    :size
  ) do
    def group_key
      [compressor_name, compressor_level]
    end
  end
end
