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
    :mean_compression_cpu_hours,
    :max_compression_max_rss,
    :mean_compressed_gibytes,
    :mean_compression_delta_gibytes,
    :geomean_compression_ratio,
    :mean_decompression_cpu_hours,
    :max_decompression_max_rss,
    :total_cpu_hours,
    :compressed_size_cost,
    :compression_time_cost,
    :decompression_time_cost
  ) do
    def dominates?(other)
      total_cpu_hours < other.total_cpu_hours &&
        mean_compressed_gibytes < other.mean_compressed_gibytes
    end

    def total_time_cost
      compression_time_cost + decompression_time_cost
    end

    def total_cost
      compressed_size_cost + total_time_cost
    end

    def to_s
      gib_saved = mean_compression_delta_gibytes
      <<-STRING
#{compressor_name} level #{compressor_level}:
  compression ratio           : #{format('%.2f', geomean_compression_ratio)}
  compression CPU hours       : #{format('%.1f', mean_compression_cpu_hours)}
  compression max RSS (KiB)   : #{format('%d', max_compression_max_rss)}
  compressed GiB              : #{format('%.1f', mean_compressed_gibytes)}
  GiB saved                   : #{format('%.1f', gib_saved)}
  decompression CPU hours     : #{format('%.1f', mean_decompression_cpu_hours)}
  decompression max RSS (KiB) : #{format('%d', max_decompression_max_rss)}
  total CPU hours             : #{format('%.1f', total_cpu_hours)}
  ------------------
  storage cost                : #{format('$%0.02f', compressed_size_cost)}
  compute cost                : #{format('$%0.02f', total_time_cost)}
  total cost                  : #{format('$%0.02f', total_cost)}
      STRING
    end
  end
end
