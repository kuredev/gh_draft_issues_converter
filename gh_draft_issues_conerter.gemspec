# frozen_string_literal: true

require_relative "lib/gh_draft_issues_conerter/version"

Gem::Specification.new do |spec|
  spec.name = "gh_draft_issues_conerter"
  spec.version = GhDraftIssuesConerter::VERSION
  spec.authors = ["Akira Kure"]
  spec.email = ["kuredev@users.noreply.github.com"]

  spec.summary = "Convert GitHub's DraftIssues to Issues"
  spec.description = "Convert GitHub's DraftIssues to Issues"
  spec.homepage = "https://github.com/kuredev/gh_draft_issues_conerter"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kuredev/gh_draft_issues_conerter"
  spec.metadata["changelog_uri"] = "https://github.com/kuredev/gh_draft_issues_conerter"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "graphlient"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
