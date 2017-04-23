# frozen_string_literal: true

module CompareCompressors
  #
  # Plot compression results to gnuplot in 2D cost space (time cost and space
  # cost).
  #
  class CostPlotter < Plotter
    DEFAULT_SHOW_COST_CONTOURS = true

    def initialize(cost_model, **options)
      @cost_model = cost_model
      @show_cost_contours = \
        if options.key?(:show_cost_contours)
          options.delete(:show_cost_contours)
        else
          DEFAULT_SHOW_COST_CONTOURS
        end
      super(**options)
    end

    attr_reader :cost_model
    attr_reader :show_cost_contours

    def write_style
      super

      io.puts 'set view map'
      io.puts 'set contour'
      io.puts 'set palette gray'
      io.puts 'set cntrlabel font ",8"'
      io.puts 'set style textbox opaque noborder'
      io.puts 'set cbrange [0:1]' # TODO: find max cost?
      io.puts 'unset colorbox'
    end

    def splots
      splots = []
      splots.concat(contour_splots) if show_cost_contours
      splots.concat(points_splots)
      splots.concat(point_label_splots) if show_labels
      splots
    end

    def points_splots
      compressor_names.map do |name|
        columns = CostedGroupResult.column_indexes(:hour_cost, :gibyte_cost, 0)
        "'$#{name}' using #{columns.join(':')} with points nocontour" \
        " title '#{find_display_name(name)}'"
      end
    end

    def point_label_splots
      compressor_names.map do |name|
        columns = CostedGroupResult.column_indexes(
          :hour_cost, :gibyte_cost, 0, :compressor_level
        )
        "'$#{name}' using #{columns.join(':')} with labels nocontour notitle"
      end
    end

    def contour_splots
      [
        'x + y with lines palette notitle nosurface',
        'x + y with labels boxed notitle nosurface'
      ]
    end
  end
end
