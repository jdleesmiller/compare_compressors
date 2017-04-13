# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Run compressors on targets and record the results.
  #
  # The general approach is, for each target:
  #
  # 1. Copy the original target (read only) to a temporary folder (read write);
  #    the copy is the 'work target'.
  # 2. Hash the work target so we can make sure we don't change it.
  # 3. For each compressor and level, compress the work target.
  # 4. Remove the work target (if the compressor left it)
  # 5. Decompress the compressed target; this should restore the work target.
  # 6. Check the work target's hash before we start the next compressor or
  #    level, to make sure the compression hasn't broken it somehow.
  #
  # This approach is a bit complicated, but it lets us (1) make sure we don't
  # change the original targets, since they're copied, (2) make sure we
  # don't accidentally change the work target during the run, which would
  # invalidate the results, and (3) avoid copying the work target from the
  # target repeatedly.
  #
  class Comparer
    #
    # @param [CSV] csv CSV writer for output
    # @param [Array<Compressor>] compressors
    # @param [Array<String>] targets pathnames of targets (read only)
    #
    def run(csv, compressors, targets)
      csv << Result.members
      targets.each do |target|
        Dir.mktmpdir do |tmp|
          work_target = stage_target(tmp, target)
          evaluate_target(csv, compressors, target, work_target)
        end
      end
      nil
    end

    private

    def stage_target(tmp, target)
      pathname = File.join(tmp, 'data')
      FileUtils.cp target, pathname
      pathname
    end

    def evaluate_target(csv, compressors, target, work_target)
      target_digest = find_digest(work_target)
      compressors.each do |compressor|
        compressor.levels.each do |level|
          if find_digest(work_target) != target_digest
            raise "digest mismatch: #{compressor.name}" \
              " level #{level} on #{target}"
          end
          csv << compressor.evaluate(target, work_target, level)
        end
      end
    end

    def find_digest(pathname)
      Digest::SHA256.file(pathname).hexdigest
    end
  end
end
