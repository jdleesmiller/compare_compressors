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

    def initialize(
      gibyte_cost: DEFAULT_GIBYTE_COST,
      compression_hour_cost: DEFAULT_HOUR_COST,
      decompression_hour_cost: DEFAULT_HOUR_COST
    )
      @gibyte_cost = gibyte_cost
      @compression_hour_cost = compression_hour_cost
      @decompression_hour_cost = decompression_hour_cost
    end

    attr_reader :gibyte_cost
    attr_reader :compression_hour_cost
    attr_reader :decompression_hour_cost

    def cost(grouped_results)
      grouped_results.map do |group_result|
        CostedGroupResult.new(self, group_result)
      end
    end

    def summarize(costed_grouped_results, top = 5)
      costed_grouped_results.sort_by(&:total_cost).take(top)
    end
  end
end
