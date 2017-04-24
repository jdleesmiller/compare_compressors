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
        io.puts 'set xlabel "Decompression Time (CPU hours)"'
      else
        io.puts 'set xlabel "Compression Time (CPU hours)"'
      end
    end

    def write_plots
      io.puts "plot #{plots.join(", \\\n  ")}"
    end

    def x_column
      if decompression
        :mean_decompression_cpu_hours
      else
        :mean_compression_cpu_hours
      end
    end

    def plots
      compressor_names.map do |name|
        columns = GroupResult.column_indexes(
          x_column, :mean_compressed_gibytes
        ).join(':')
        "'$#{name}' using #{columns} with points" \
        " #{point_style(name)}" \
        " title '#{find_display_name(name)}'"
      end
    end
  end
end
