# frozen_string_literal: true

require "optparse"

# Example
#   bundle exec ruby　gh_draft_issues_conerter --projects_number N --repository_name "XXX"

module GhDraftIssuesConerter
  class CLI
    def self.start(argv)
      options = {}
      options[:interval] = 25 # Default

      OptionParser.new do |opts|
        opts.banner = "Usage: bundle exec ruby gh-draft-issues-conerter --projects_number N --repository_name xxxxx"

        opts.on("-p N", "--projects_number N", "project number") do |projects_number|
          pp "---"
          pp projects_number

          options[:projects_number] = projects_number.to_i
        end

        opts.on("-r NAME", "--repository_name NAME", "full repository name. ex: [owner]/[repository]") do |repository_name|
          options[:repository_name] = repository_name
        end

        opts.on("-i SECONDS", "--interval SECONDS", "(option)interval seconds for create issue.default: 25s") do |interval|
          options[:interval] = interval.to_i
        end
      end.parse!(argv)

      # Check must option
      if options[:projects_number].nil?
        puts "Error: --projects_number option is required."
        exit 1
      end

      # Check must option
      if options[:repository_name].nil?
        puts "Error: --repository_name option is required. ex: sample_user/sample_repository"
        exit 1
      end

      if ENV["GITHUB_KEY"].nil?
        puts "Environment value `GITHUB_KEY` is required."
        exit 1
      end

      converter = GhDraftIssueConverter::Converter.new(ENV["GITHUB_KEY"])
      repository = GhDraftIssueConverter::Repository.new(options[:repository_name])
      converter.run(
        options[:projects_number],
        repository,
        options[:interval],
      )
    end
  end
end
