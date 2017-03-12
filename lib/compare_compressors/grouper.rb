# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Group and summarise results.
  #
  class Grouper
    # Default to current Amazon S3 storage cost per GiB*month ($).
    DEFAULT_GIBYTE_COST = 0.023

    # Default to # on-demand cost for an Amazon EC2 m1.medium ($).
    DEFAULT_HOUR_COST = 0.047

    def initialize(gibyte_cost:, hour_cost:, scale:)
      @gibyte_cost = gibyte_cost.to_f
      @hour_cost = hour_cost.to_f
      @scale = scale.to_f
    end

    attr_reader :gibyte_cost
    attr_reader :hour_cost
    attr_reader :scale

    def group(results)
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

    def find_non_dominated(group_results)
      group_results.reject do |group_result0|
        group_results.any? do |group_result1|
          group_result1.dominates?(group_result0)
        end
      end
    end
  end
end
