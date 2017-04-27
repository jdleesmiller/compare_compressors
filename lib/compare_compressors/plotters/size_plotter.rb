# frozen_string_literal: true

module CompareCompressors
  #
  # Plot grouped compression results to gnuplot in 2D --- just compression time
  # or decompression time vs size.
  #
  class SizePlotter < Plotter
    DEFAULT_DECOMPRESSION = false # plot compression by default

    def initialize(**options)
      @decompression = \
        if options.key?(:decompression)
          options.delete(:decompression)
        else
          DEFAULT_DECOMPRESSION
        end
      super(**options)
    end

    attr_reader :decompression

    def write_labels
      io.puts 'set ylabel "Compressed Size (GiB)"'
      if decompression
        io.puts "set xlabel 'Decompression Time #{time_unit}'"
      else
        io.puts "set xlabel 'Compression Time #{time_unit}'"
      end
    end

    def time_column_name
      if decompression && use_cpu_time
        :mean_decompression_cpu_hours
      elsif decompression
        :mean_decompression_elapsed_hours
      elsif use_cpu_time
        :mean_compression_cpu_hours
      else
        :mean_compression_elapsed_hours
      end
    end

    def column_names
      [time_column_name, :mean_compressed_gibytes]
    end

    def write_plots
      io.puts "plot #{plots.join(", \\\n  ")}"
    end

    def plots
      if show_labels
        point_plots + point_label_plots
      else
        point_plots
      end
    end

    def point_plots
      compressor_names.map do |name|
        "'$#{name}' using #{column_numbers.join(':')} with points" \
        " #{point_style(name)}" \
        " title '#{find_display_name(name)}'"
      end
    end

    def point_label_plots
      compressor_names.map do |name|
        columns = column_numbers(column_names + [:compressor_level])
        "'$#{name}' using #{columns.join(':')}" \
        ' with labels left offset 0, character 0.5 notitle'
      end
    end
  end
end
