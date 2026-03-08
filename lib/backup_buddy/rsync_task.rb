# frozen_string_literal: true

module BackupBuddy
  # Immutable data object representing a single rsync invocation.
  # The factory spawns these; the manager runs them.
  class RsyncTask
    attr_reader :command, :label

    def initialize(command:, label:)
      @command = command
      @label = label
      freeze
    end
  end
end
