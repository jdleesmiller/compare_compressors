# frozen_string_literal: true

module CompareCompressors
  #
  # Define costs for comparing grouped results.
  #
  class CostModel
    # Default to current Amazon S3 storage cost per GiB*month ($).
    DEFAULT_GIBYTE_COST = 0.023

    # Default to on-demand cost for an Amazon EC2 m3.medium ($).
    DEFAULT_HOUR_COST = 0.073

    # Default to elapsed time rather than CPU time.
    DEFAULT_USE_CPU_TIME = false

    # Default to dollars.
    DEFAULT_CURRENCY = '$'

    # Default to dollars.
    DEFAULT_SUMMARIZE_TOP = 5

    def initialize(
      gibyte_cost: DEFAULT_GIBYTE_COST,
      compression_hour_cost: DEFAULT_HOUR_COST,
      decompression_hour_cost: DEFAULT_HOUR_COST,
      use_cpu_time: DEFAULT_USE_CPU_TIME,
      currency: DEFAULT_CURRENCY
    )
      @gibyte_cost = gibyte_cost
      @compression_hour_cost = compression_hour_cost
      @decompression_hour_cost = decompression_hour_cost
      @use_cpu_time = use_cpu_time
      @currency = currency
    end

    attr_reader :gibyte_cost
    attr_reader :compression_hour_cost
    attr_reader :decompression_hour_cost
    attr_reader :use_cpu_time
    attr_reader :currency

    def cost(grouped_results)
      grouped_results.map do |group_result|
        CostedGroupResult.new(self, group_result)
      end
    end

    def summarize(costed_grouped_results, top = DEFAULT_SUMMARIZE_TOP)
      costed_grouped_results.sort_by(&:total_cost).take(top).map do |result|
        result.to_s(currency)
      end
    end
  end
end
