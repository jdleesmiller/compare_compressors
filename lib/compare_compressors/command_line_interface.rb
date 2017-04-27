# frozen_string_literal: true

require 'csv'
require 'thor'

module CompareCompressors
  #
  # Handle generic command line options and run the relevant command.
  #
  class CommandLineInterface < Thor
    desc \
      'version',
      'print version (also available as --version)'
    def version
      puts "compare_compressors-#{CompareCompressors::VERSION}"
      COMPRESSORS.each do |compressor|
        puts format('%10s: %s', compressor.name, compressor.version || '?')
      end
    end
    map %w(--version -v) => :version

    desc \
      'compare <target files>',
      'Run compression tools on targets and write a CSV'
    def compare(*targets)
      CSV do |csv|
        Comparer.new.run(csv, COMPRESSORS, targets)
      end
    end

    class <<self
      def scale_option
        option \
          :scale,
          type: :numeric,
          desc: 'scale factor from sample targets to full dataset',
          default: 1.0
      end

      def use_cpu_time_option
        option \
          :use_cpu_time,
          type: :boolean,
          desc: 'use CPU time rather than elapsed time',
          default: CostModel::DEFAULT_USE_CPU_TIME
      end

      def cost_options
        option \
          :gibyte_cost,
          type: :numeric,
          desc: 'storage cost per gigabyte of compressed output',
          default: CostModel::DEFAULT_GIBYTE_COST
        option \
          :compression_hour_cost,
          type: :numeric,
          desc: 'compute cost per hour of CPU time for compression',
          default: CostModel::DEFAULT_HOUR_COST
        option \
          :decompression_hour_cost,
          type: :numeric,
          desc: 'compute cost per hour of CPU time for decompression',
          default: CostModel::DEFAULT_HOUR_COST
      end

      def plot_options
        option \
          :terminal,
          desc: 'the terminal line for gnuplot',
          default: Plotter::DEFAULT_TERMINAL
        option \
          :output,
          desc: 'the output name for gnuplot',
          default: Plotter::DEFAULT_OUTPUT
        option \
          :pareto_only,
          desc: 'plot only non-dominated compressor-level pairs',
          type: :boolean,
          default: true
        option \
          :logscale_size,
          desc: 'use a log10 scale for the size (lucky you if you need this)',
          type: :boolean,
          default: Plotter::DEFAULT_LOGSCALE_SIZE
        option \
          :autoscale_fix,
          desc: 'zoom axes to fit the points tightly',
          type: :boolean,
          default: Plotter::DEFAULT_AUTOSCALE_FIX
        option \
          :show_labels,
          desc: 'show compression level labels on the plot',
          type: :boolean,
          default: Plotter::DEFAULT_SHOW_LABELS
        option \
          :lmargin,
          desc: 'adjust lmargin (workaround if y label is cut off on png)',
          type: :numeric,
          default: Plotter::DEFAULT_LMARGIN
        option \
          :title,
          desc: 'main title (must not contain double quotes)',
          type: :string,
          default: Plotter::DEFAULT_TITLE
      end
    end

    desc \
      'plot [csv file]',
      'Write a gnuplot script for a basic 2D plot with the CSV from compare'
    scale_option
    use_cpu_time_option
    plot_options
    option \
      :decompression,
      desc: 'show decompression time instead of compression time',
      type: :boolean,
      default: SizePlotter::DEFAULT_DECOMPRESSION
    def plot(csv_file = nil)
      results = read_results(csv_file)
      group_results = GroupResult.group(results, scale: options[:scale])
      plotter = make_plotter(
        SizePlotter, options,
        decompression: options[:decompression]
      )
      plotter.plot(group_results, pareto_only: options[:pareto_only])
    end

    desc \
      'plot_3d [csv file]',
      'Write a gnuplot script for a 3D plot with the CSV from compare'
    scale_option
    use_cpu_time_option
    plot_options
    def plot_3d(csv_file = nil)
      results = read_results(csv_file)
      group_results = GroupResult.group(results, scale: options[:scale])
      plotter = make_plotter(RawPlotter, options)
      plotter.plot(group_results, pareto_only: options[:pareto_only])
    end

    desc \
      'plot_costs [csv file]',
      'Write a gnuplot script for a 2D cost plot with the CSV from compare'
    scale_option
    use_cpu_time_option
    cost_options
    plot_options
    option \
      :show_cost_contours,
      desc: 'show cost function contours',
      type: :boolean,
      default: CostPlotter::DEFAULT_SHOW_COST_CONTOURS
    def plot_costs(csv_file = nil)
      results = read_results(csv_file)
      group_results = GroupResult.group(results, scale: options[:scale])
      cost_model = make_cost_model(options)
      costed_group_results =
        CostedGroupResult.from_group_results(cost_model, group_results)
      plotter = make_plotter(
        CostPlotter, options, cost_model,
        show_cost_contours: options[:show_cost_contours]
      )
      plotter.plot(costed_group_results, pareto_only: options[:pareto_only])
    end

    desc \
      'summarize [csv file]',
      'Read CSV from compare and write out a summary'
    scale_option
    use_cpu_time_option
    cost_options
    def summarize(csv_file = nil)
      results = read_results(csv_file)
      group_results = GroupResult.group(results, scale: options[:scale])
      cost_model = make_cost_model(options)
      costed_group_results =
        CostedGroupResult.from_group_results(cost_model, group_results)
      puts cost_model.summarize(costed_group_results)
    end

    private

    def make_cost_model(options)
      CostModel.new(
        gibyte_cost: options[:gibyte_cost],
        compression_hour_cost: options[:compression_hour_cost],
        decompression_hour_cost: options[:decompression_hour_cost],
        use_cpu_time: options[:use_cpu_time]
      )
    end

    def make_plotter(klass, options, *args, **kwargs)
      klass.new(
        *args,
        terminal: options[:terminal],
        output: options[:output],
        logscale_size: options[:logscale_size],
        autoscale_fix: options[:autoscale_fix],
        show_labels: options[:show_labels],
        lmargin: options[:lmargin],
        title: options[:title],
        use_cpu_time: options[:use_cpu_time],
        **kwargs
      )
    end

    def read_results(csv_file)
      Result.read_csv(csv_file ? File.read(csv_file) : STDIN)
    end
  end
end
