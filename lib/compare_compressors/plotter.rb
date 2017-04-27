# frozen_string_literal: true

module CompareCompressors
  #
  # Plot compression results to gnuplot.
  #
  class Plotter
    DEFAULT_TERMINAL = 'png size 640, 480'
    DEFAULT_OUTPUT = 'compare_compressors.png'
    DEFAULT_LOGSCALE_SIZE = false
    DEFAULT_AUTOSCALE_FIX = false
    DEFAULT_SHOW_LABELS = true
    DEFAULT_LMARGIN = nil
    DEFAULT_TITLE = nil
    DEFAULT_USE_CPU_TIME = false

    def initialize(
      terminal:, output:, logscale_size:, autoscale_fix:,
      show_labels:, lmargin:, title:, use_cpu_time:
    )
      @terminal = terminal
      @output = output
      @logscale_size = logscale_size
      @autoscale_fix = autoscale_fix
      @show_labels = show_labels
      @lmargin = lmargin
      @title = title
      @use_cpu_time = use_cpu_time

      @group_results = nil
      @io = nil
    end

    attr_reader :terminal
    attr_reader :output
    attr_reader :logscale_size
    attr_reader :autoscale_fix
    attr_reader :show_labels
    attr_reader :lmargin
    attr_reader :title
    attr_reader :use_cpu_time

    attr_reader :group_results
    attr_reader :io

    def plot(group_results, pareto_only:, io: STDOUT)
      group_results = find_non_dominated(group_results) if pareto_only
      @group_results = group_results
      @io = io
      write
    end

    private

    def write
      write_preamble
      write_data
      write_labels
      write_style
      write_plots
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
      io.puts "set title #{escape(title)}" if title
      io.puts 'set key outside'
      io.puts "set lmargin #{lmargin}" if lmargin

      io.puts 'set logscale y' if logscale_size
      io.puts 'set autoscale fix' if autoscale_fix
    end

    def write_labels
      # Subclasses can label the axes.
    end

    def column_names
      # Subclasses can declare their column names.
    end

    def splots
      []
    end

    def write_plots
      io.puts "splot #{splots.join(", \\\n  ")}"
    end

    def time_unit
      if use_cpu_time
        '(CPU Hours)'
      else
        '(Hours)'
      end
    end

    def compressor_names
      group_results.map(&:compressor_name).uniq.sort
    end

    def compressor_number(compressor_name)
      COMPRESSORS.index { |c| c.name == compressor_name } + 1
    end

    def point_style(name)
      number = compressor_number(name)
      "linecolor #{number} pointtype #{number}"
    end

    def find_display_name(compressor_name)
      compressor = COMPRESSORS.find { |c| c.name == compressor_name }
      compressor&.display_name || compressor_name
    end

    def column_numbers(names = column_names)
      struct = @group_results.first.class
      names.map { |name| struct.members.index(name) + 1 }
    end

    #
    # Find points on the Pareto frontier using the axes shown in the graph.
    #
    # @param [Array.<Struct>] points
    # @return [Array.<Struct>]
    #
    def find_non_dominated(points)
      points.reject do |point0|
        points.any? do |point1|
          dominates?(point1, point0)
        end
      end
    end

    #
    # Check whether `point1` dominates `point0`. Here we assume that we are
    # minimizing on all columns.
    #
    def dominates?(point1, point0)
      column_names.all? { |name| point1[name] < point0[name] }
    end

    #
    # Make at least some attempt to escape double quotes.
    #
    def escape(str)
      str.dump
    end
  end
end
