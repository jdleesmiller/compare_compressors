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

    private

    def column_values(column_name)
      group_results.map(&column_name)
    end

    def color_palette_range
      min_cost = column_names.map { |name| column_values(name).min }.inject(&:+)
      max_cost = column_names.map { |name| column_values(name).max }.inject(&:+)
      [min_cost / 2.0, max_cost]
    end

    def write_style
      super

      io.puts 'set view map'
      io.puts 'set contour'
      io.puts 'set palette gray'
      io.puts 'set cntrlabel font ",10"'
      io.puts 'set style textbox opaque noborder'
      io.puts "set cbrange [#{color_palette_range.join(':')}]"
      io.puts 'unset colorbox'
    end

    def write_labels
      io.puts "set xlabel 'Time Cost (#{cost_model.currency})'"
      io.puts "set ylabel 'Size Cost (#{cost_model.currency})'"
    end

    def column_names
      %i[hour_cost gibyte_cost]
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
        columns = column_numbers + [0]
        "'$#{name}' using #{columns.join(':')} with points nocontour" \
        " #{point_style(name)}" \
        " title '#{find_display_name(name)}'"
      end
    end

    def point_label_splots
      compressor_names.map do |name|
        columns = column_numbers + [0] + column_numbers([:compressor_level])
        "'$#{name}' using #{columns.join(':')} with labels" \
        ' left nocontour notitle'
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
