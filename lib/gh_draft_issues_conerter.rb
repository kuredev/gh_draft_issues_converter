# frozen_string_literal: true

require_relative "gh_draft_issues_conerter/version"
require_relative "gh_draft_issues_conerter/cli"
require_relative "gh_draft_issues_conerter/gh_draft_issues_conerter"

module GhDraftIssuesConerter
  class Error < StandardError; end
end
