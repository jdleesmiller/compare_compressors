# frozen_string_literal: true

module CompareCompressors
  #
  # Grouped result with costs calculated.
  #
  CostedGroupResult = Struct.new(
    :compressor_name,
    :compressor_level,
    :mean_compression_elapsed_hours,
    :mean_compression_cpu_hours,
    :max_compression_max_rss,
    :mean_compressed_gibytes,
    :mean_compression_delta_gibytes,
    :geomean_compression_ratio,
    :mean_decompression_elapsed_hours,
    :mean_decompression_cpu_hours,
    :max_decompression_max_rss,
    :compression_hour_cost,
    :decompression_hour_cost,
    :hour_cost,
    :gibyte_cost,
    :total_cost
  ) do
    def self.new_from_group_result(cost_model, group_result)
      if cost_model.use_cpu_time
        compression_hours = group_result.mean_compression_cpu_hours
        decompression_hours = group_result.mean_decompression_cpu_hours
      else
        compression_hours = group_result.mean_compression_elapsed_hours
        decompression_hours = group_result.mean_decompression_elapsed_hours
      end
      compression_hour_cost =
        cost_model.compression_hour_cost * compression_hours
      decompression_hour_cost =
        cost_model.decompression_hour_cost * decompression_hours
      hour_cost = compression_hour_cost + decompression_hour_cost
      gibyte_cost =
        cost_model.gibyte_cost *
        group_result.mean_compressed_gibytes
      new(
        group_result.compressor_name,
        group_result.compressor_level,
        group_result.mean_compression_cpu_hours,
        group_result.mean_compression_elapsed_hours,
        group_result.max_compression_max_rss,
        group_result.mean_compressed_gibytes,
        group_result.mean_compression_delta_gibytes,
        group_result.geomean_compression_ratio,
        group_result.mean_decompression_elapsed_hours,
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

    def to_s(currency = CostModel::DEFAULT_CURRENCY)
      gib_saved = mean_compression_delta_gibytes
      <<~STRING
        #{compressor_name} level #{compressor_level}:
          compression ratio           : #{format('%.2f', geomean_compression_ratio)}
          compression elapsed hours   : #{format('%.4f', mean_compression_elapsed_hours)}
          compression CPU hours       : #{format('%.4f', mean_compression_cpu_hours)}
          compression max RSS (KiB)   : #{format('%d', max_compression_max_rss)}
          compressed GiB              : #{format('%.4f', mean_compressed_gibytes)}
          GiB saved                   : #{format('%.2f', gib_saved)}
          decompression elapsed hours : #{format('%.4f', mean_decompression_elapsed_hours)}
          decompression CPU hours     : #{format('%.4f', mean_decompression_cpu_hours)}
          decompression max RSS (KiB) : #{format('%d', max_decompression_max_rss)}
          ------------------
          storage cost                : #{format('%s%0.02f', currency, gibyte_cost)}
          compute cost                : #{format('%s%0.02f', currency, hour_cost)}
          total cost                  : #{format('%s%0.02f', currency, total_cost)}
      STRING
    end
  end
end
