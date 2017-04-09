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
    :max_rss,
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

    def total_cost
      compressed_size_cost + compression_time_cost
    end

    def to_s
      <<-STRING
#{compressor_name} level #{compressor_level}:
  compression ratio: #{format('%.2f', geomean_compression_ratio)}
  compute CPU hours: #{format('%.1f', mean_hours)}
  max RSS (KiB)    : #{format('%d', max_rss)}
  compressed GiB   : #{format('%.1f', mean_compressed_gibytes)}
  GiB saved        : #{format('%.1f', mean_compression_delta_gibytes)}
  ------------------
  storage cost     : #{format('$%0.02f', compressed_size_cost)}
  compute cost     : #{format('$%0.02f', compression_time_cost)}
  total cost       : #{format('$%0.02f', total_cost)}
      STRING
    end
  end
end
