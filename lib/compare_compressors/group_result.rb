# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # A single compressor-level result averaged the over targets.
  #
  GroupResult = Struct.new(
    :compressor_name,
    :compressor_level,
    :mean_hours,
    :mean_compressed_gibytes,
    :mean_compression_delta_gibytes,
    :geomean_compression_ratio,
    :compressed_size_cost,
    :compression_time_cost
  ) do
    def dominates?(other)
      mean_hours < other.mean_hours &&
        mean_compressed_gibytes < other.mean_compressed_gibytes
    end
  end
end
