# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Plot compression results to gnuplot.
  #
  class Plotter
    def initialize(grouper)
      @grouper = grouper
      @terminal = 'png size 640, 480'
      @output = 'compare_compressors.png'
      @logscale_y = false
      @autoscale_fix = false

      @io = nil
      @group_results = nil
    end

    attr_accessor :terminal
    attr_accessor :output
    attr_accessor :logscale_y
    attr_accessor :autoscale_fix

    attr_reader :grouper
    attr_reader :io
    attr_reader :group_results

    def gibyte_cost
      grouper.gibyte_cost
    end

    def hour_cost
      grouper.hour_cost
    end

    def self.gnuplot_installed?
      `which gnuplot`.chomp != ''
    end

    def plot(group_results)
      @io = STDOUT
      @group_results = group_results
      write
    end

    private

    def write
      write_preamble
      write_data
      write_style
      write_splot
    end

    def write_preamble
      io.puts "set terminal #{terminal}"
      io.puts "set output '#{output}'"
    end

    def write_data
      group_results_by_name = group_results.group_by(&:compressor_name)
      group_results_by_name.each do |name, name_results|
        io.puts "$#{name} << EOD"
        name_results.each do |name_result|
          io.puts name_result.to_a.join(' ')
        end
        io.puts 'EOD'
      end
    end

    def write_style
      write_cost_contour_style
      write_axes_style

      io.puts 'set logscale y' if logscale_y
      io.puts 'set autoscale fix' if autoscale_fix
    end

    def write_cost_contour_style
      io.puts 'set view map'
      io.puts 'set contour'
      io.puts 'set palette gray'
      io.puts 'set cntrlabel font ",8"'
      io.puts 'set style textbox opaque noborder'
      io.puts 'unset colorbox'
      io.puts "cost(x, y) = #{hour_cost} * x + #{gibyte_cost} * y"
    end

    def write_axes_style
      io.puts 'set xlabel "Compression Time (hours)"'
      io.puts 'set ylabel "Compressed Size (GiB)"'
      io.puts 'set key outside'

      # Work around apparent bug in gnuplot (5.0.5): putting the key outside
      # pushes the left margin off out of the canvas for the PNG terminal.
      io.puts 'set lmargin 5' if terminal.start_with?('png')
    end

    def write_splot
      splots = contour_splots + points_splots + point_label_splots
      io.puts "splot #{splots.join(", \\\n  ")}"
    end

    def compressor_names
      group_results.map(&:compressor_name).uniq.sort
    end

    def find_display_name(compressor_name)
      compressor = COMPRESSORS.find { |c| c.name == compressor_name }
      compressor&.display_name || compressor_name
    end

    def points_splots
      compressor_names.map do |name|
        columns = using_columns(:mean_hours, :mean_compressed_gibytes, 0)
        "'$#{name}' using #{columns} with points nocontour" \
        " title '#{find_display_name(name)}'"
      end
    end

    def point_label_splots
      compressor_names.map do |name|
        columns = using_columns(
          :mean_hours, :mean_compressed_gibytes, 0, :compressor_level
        )
        "'$#{name}' using #{columns} with labels nocontour notitle"
      end
    end

    def contour_splots
      [
        'cost(x, y) with lines palette notitle nosurface',
        'cost(x, y) with labels boxed notitle nosurface'
      ]
    end

    #
    # Look up the column indexes for the given GroupResult columns.
    #
    def using_columns(*column_names)
      indexes = column_names.map do |name|
        name.is_a?(Numeric) ? name : GroupResult.members.index(name) + 1
      end
      indexes.join(':')
    end
  end
end
