# frozen_string_literal: true

module CompareCompressors
  #
  # Grouped result with costs calculated.
  #
  CostedGroupResult = Struct.new(
    :compressor_name,
    :compressor_level,
    :mean_compression_cpu_hours,
    :max_compression_max_rss,
    :mean_compressed_gibytes,
    :mean_compression_delta_gibytes,
    :geomean_compression_ratio,
    :mean_decompression_cpu_hours,
    :max_decompression_max_rss,
    :compression_hour_cost,
    :decompression_hour_cost,
    :hour_cost,
    :gibyte_cost,
    :total_cost
  ) do
    def self.new_from_group_result(cost_model, group_result)
      compression_hour_cost =
        cost_model.compression_hour_cost *
        group_result.mean_compression_cpu_hours
      decompression_hour_cost =
        cost_model.decompression_hour_cost *
        group_result.mean_decompression_cpu_hours
      hour_cost = compression_hour_cost + decompression_hour_cost
      gibyte_cost =
        cost_model.gibyte_cost *
        group_result.mean_compressed_gibytes
      new(
        group_result.compressor_name,
        group_result.compressor_level,
        group_result.mean_compression_cpu_hours,
        group_result.max_compression_max_rss,
        group_result.mean_compressed_gibytes,
        group_result.mean_compression_delta_gibytes,
        group_result.geomean_compression_ratio,
        group_result.mean_decompression_cpu_hours,
        group_result.max_decompression_max_rss,
        compression_hour_cost,
        decompression_hour_cost,
        hour_cost,
        gibyte_cost,
        hour_cost + gibyte_cost
      )
    end

    def self.from_group_results(cost_model, group_results)
      group_results.map do |group_result|
        new_from_group_result(cost_model, group_result)
      end
    end

    #
    # Find costed grouped results on the Pareto frontier of the given set of
    # costed grouped results.
    #
    # @param [Array.<GroupResult>] group_results
    # @return [Array.<GroupResult>]
    #
    def self.find_non_dominated(costed_group_results)
      costed_group_results.reject do |costed_group_result0|
        costed_group_results.any? do |costed_group_result1|
          costed_group_result1.dominates?(costed_group_result0)
        end
      end
    end

    #
    # Dominates on both space and time criteria.
    #
    # @param [CostedGroupResult] other
    #
    def dominates?(other)
      hour_cost < other.hour_cost && gibyte_cost < other.gibyte_cost
    end

    #
    # Look up the column indices for the given columns by name.
    #
    # @param [Array.<[Symbol, Integer]>]
    # @return [Array.<Integer>]
    #
    def self.column_indexes(*column_names)
      column_names.map do |name|
        name.is_a?(Integer) ? name : members.index(name) + 1
      end
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
  ------------------
  storage cost                : #{format('$%0.02f', gibyte_cost)}
  compute cost                : #{format('$%0.02f', hour_cost)}
  total cost                  : #{format('$%0.02f', total_cost)}
      STRING
    end
  end
end
