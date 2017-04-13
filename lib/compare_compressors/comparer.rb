# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Run compressors on targets and record the results.
  #
  class Comparer
    def run(csv, compressors, targets)
      csv << Result.members
      Dir.mktmpdir do |tmp|
        targets.each do |target|
          evaluate_target(csv, tmp, compressors, target)
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

    def evaluate_target(csv, tmp, compressors, target)
      target_pathname = stage_target(tmp, target)
      target_digest = find_digest(target_pathname)
      compressors.each do |compressor|
        compressor.levels.each do |level|
          if find_digest(target_pathname) != target_digest
            raise "digest mismatch: #{compressor.name}" \
              " level #{level} on #{target}"
          end
          csv << compressor.evaluate(tmp, target, target_pathname, level)
        end
      end
    end

    def find_digest(pathname)
      Digest::SHA256.file(pathname).hexdigest
    end
  end
end
