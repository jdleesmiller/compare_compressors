# frozen_string_literal: true

module CompareCompressors
  #
  # Plot grouped compression results to gnuplot in 3D (compression time,
  # decompression time, and compressed size).
  #
  class RawPlotter < Plotter
    DEFAULT_VIEW_ROT_X = 30
    DEFAULT_VIEW_ROT_Z = 350

    def initialize(**options)
      @view_rot_x = options.delete(:view_rot_x) || DEFAULT_VIEW_ROT_X
      @view_rot_z = options.delete(:view_rot_z) || DEFAULT_VIEW_ROT_Z
      super(**options)
    end

    attr_reader :view_rot_x
    attr_reader :view_rot_z

    def write_style
      super
      io.puts format('set view %d, %d', view_rot_x, view_rot_z)
      io.puts 'set grid xtics ytics ztics'
    end

    def write_labels
      io.puts 'set xlabel "Compression Time (CPU hours)" rotate parallel'
      io.puts 'set ylabel "Compressed Size (GiB)" rotate parallel'
      io.puts 'set zlabel "Decompression Time (CPU hours)" rotate parallel'
    end

    def splots
      points_splots
    end

    def points_splots
      compressor_names.map do |name|
        columns = GroupResult.column_indexes(
          :mean_compression_cpu_hours,
          :mean_compressed_gibytes,
          :mean_decompression_cpu_hours
        ).join(':')
        "'$#{name}' using #{columns} with points" \
        " title '#{find_display_name(name)}'"
      end
    end
  end
end
