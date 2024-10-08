# Overview
A tool to batch convert Draft Issues to Issues in GitHub Projects.

https://kuredev.hashnode.dev/i-built-a-tool-to-batch-convert-draft-issues-to-issues-in-github-projects

# Installation

```sh
% gem install gh_draft_issues_converter
```

# Usage

Prerequisites:

- Project number (specify with `-p`)
  - ex) "In the URL `https://github.com/users/kuredev/projects/1`, the `1` corresponds to the project number."
- Repository name (owner/repository, specify with `-r`)
- GitHub Personal Token (register it as `GITHUB_KEY`)

## Example

```sh
% gh_draft_issues_converter -p 1 -r kuredev/gh-draft-issues-converter   
```

# Limitations
- Only single-select custom fields will be migrated.
- Among standard fields, only the assignee will be migrated.

# Notes
To avoid rate limits with the CreateIssue API, a default interval of 25 seconds is set. This interval can be adjusted using the `-i` option.

https://github.com/cli/cli/issues/4801#issuecomment-1431812916
