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
    def self.from_results(results, scale, gibyte_cost, hour_cost)
      results.group_by(&:group_key).map do |_, group_results|
        targets = group_results.map(&:target)
        uncompressed_sizes = targets.map { |target| File.stat(target).size }
        compression_ratios = group_results.zip(uncompressed_sizes).map do |r, u|
          u / r.size
        end
        compression_deltas = group_results.zip(uncompressed_sizes).map do |r, u|
          u - r.size
        end

        n = group_results.size.to_f
        mean_hours = scale * group_results.map(&:time).sum / n / 3600.0
        mean_compressed_gibytes =
          scale * group_results.map(&:size).sum / n / (1024**3)
        GroupResult.new(
          group_results.first.compressor_name,
          group_results.first.compressor_level,
          mean_hours,
          mean_compressed_gibytes,
          scale * compression_deltas.sum / n,
          compression_ratios.inject(&:*)**(1 / n),
          mean_compressed_gibytes * gibyte_cost,
          mean_hours * hour_cost
        )
      end
    end

    def self.find_non_dominated(group_results)
      group_results.reject do |group_result0|
        group_results.any? do |group_result1|
          group_result1.dominates?(group_result0)
        end
      end
    end

    def dominates?(other)
      mean_hours < other.mean_hours &&
        mean_compressed_gibytes < other.mean_compressed_gibytes
    end
  end
end
