# frozen_string_literal: true

require "graphlient"

module GhDraftIssueConverter
  class DraftIssue
    attr_reader :id, :title, :body, :field_values, :assign_user_ids

    # @param assign_user_ids [Array<String>]
    # @field_values [Hash]
    # [
    #   FieldValue, FieldValue
    # ]
    def initialize(id, title, body, assign_user_ids, field_values)
      @id = id
      @title = title
      @body = body
      @field_values = field_values
      @assign_user_ids = assign_user_ids
    end

    def unnecessary_for_convert_issue?
      false

      #field_values.any? do |field_value|
      #  field_value.field_name == "Status" && field_value.field_value_name == "🚫unnecessary"
      #end
    end

    def user_ids_github_format
      assign_user_ids.map { |id| "\"#{id}\""}.join(", ")
    end
  end

  class FieldValue
    attr_reader :field_value_id,
                :field_value_name,
                :field_value_option_id,
                :field_id,
                :field_name

    def initialize(field_value_id, field_value_name, field_value_option_id, field_id, field_name)
      @field_value_id = field_value_id
      @field_value_name = field_value_name
      @field_value_option_id = field_value_option_id
      @field_id = field_id
      @field_name = field_name
    end
  end

  class Repository
    attr_reader :full_repository_name
    def initialize(full_repository_name)
      parts = full_repository_name.split('/')

      if full_repository_name.include?('/')
        parts = full_repository_name.split('/')

        if parts.length != 2
          puts "repository_name is invalid"
          exit 1
        elsif parts[0].empty? || parts[1].empty?
          puts "repository_name is invalid"
          exit 1
        else
          # OK
        end
      else
        puts "repository_name is invalid"
        exit 1
      end

      @full_repository_name = full_repository_name
    end

    def name
      full_repository_name.split("/")[1]
    end

    def owner
      full_repository_name.split("/")[0]
    end
  end

  class GhResoucesManager
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # @return [String] Issue ID
    def add_issue_projectv2(project_id, issue_id)
      response = client.query <<~GRAPHQL
        mutation {
          addProjectV2ItemById(input: {projectId: "#{project_id}", contentId: "#{issue_id}"}) {
            item {
              id
            }
          }
        }
      GRAPHQL

      response.to_h["data"]["addProjectV2ItemById"]["item"]["id"]
    end

    def fetch_draft_issues(project_id)
      # https://docs.github.com/ja/graphql/reference/objects#user
      response = client.query <<~GRAPHQL
      query {
          node(id: "#{project_id}") {
            ... on ProjectV2 {
              items {
                nodes {
                  id,
                  content {
                    ... on DraftIssue {
                      title
                      body
                      assignees(first: 10) {
                        nodes {
                          id
                        }
                      }
                    }
                  }
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        id
                        optionId
                        name
                        field {
                          ... on ProjectV2SingleSelectField {
                            id
                            name
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
      }
      GRAPHQL

      nodes = response.to_h["data"]["node"]["items"]["nodes"]
      nodes.map do |node|
        next if node["content"]["__typename"] == "Issue"

        assign_user_ids = node["content"]["assignees"]["nodes"]
        assign_user_ids = assign_user_ids.map { |item| item["id"] }

        DraftIssue.new(
          node["id"],
          node["content"]["title"],
          node["content"]["body"],
          assign_user_ids,
          convert_field_nodes_to_objs(node["fieldValues"]["nodes"])
        )
      end.compact
    end

    # @return [Array<FieldValue>]
    def convert_field_nodes_to_objs(nodes)
      nodes.map do |node|
        next if node.empty?
        next if node["__typename"] != "ProjectV2ItemFieldSingleSelectValue"

        FieldValue.new(
          node["id"],
          node["name"],
          node["optionId"],
          node["field"]["id"],
          node["field"]["name"]
        )
      end.compact
    end

    def fetch_project_id(project_number, repository)
      owner_is_user = owner_is_user?(repository)
      if owner_is_user
        response = client.query <<~GRAPHQL
        query {
          user(login: "#{repository.owner}") {
            projectV2(number: #{project_number}) {
              id,
              title
            }
          }
        }
        GRAPHQL
        response.to_h["data"]["user"]["projectV2"]["id"]
      else
        response = client.query <<~GRAPHQL
        query {
          organization(login: "#{repository.owner}") {
              projectV2(number: #{project_number}) {
                id,
                title
              }
          }
        }
        GRAPHQL
        response.to_h["data"]["organization"]["projectV2"]["id"]
      end
    end

    def fetch_repository_id(repository)
      owner_is_user = owner_is_user?(repository)
      if owner_is_user
        response = client.query <<~GRAPHQL
        query {
          repository(owner: "#{repository.owner}", name: "#{repository.name}") {
            id
          }
        }
        GRAPHQL

        response.to_h["data"]["repository"]["id"]
      else
        response = client.query <<~GRAPHQL
        query {
          organization(login: "#{repository.owner}") {
            repository(name: "#{repository.name}") {
              id
            }
          }
        }
        GRAPHQL

        response.to_h["data"]["organization"]["repository"]["id"]
      end
    end

    def update_item_field_values(project_id, draft_issue, item_id)
      draft_issue.field_values.each do |field_value|
        response = client.query <<~GRAPHQL
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: "#{project_id}",
            itemId: "#{item_id}",
            fieldId: "#{field_value.field_id}",
            value: {singleSelectOptionId: "#{field_value.field_value_option_id}"}}
            ) {
            projectV2Item {
              id
            }
          }
        }
        GRAPHQL
      end
    end

    # memo: https://docs.github.com/en/graphql/reference/input-objects#createissueinput
    # @return [String] item_id
    def create_issue_from_draft(draft_issue, repository_id, project_id)
      response = client.query <<~GRAPHQL
        mutation {
          createIssue(input: {
            repositoryId: "#{repository_id}",
            assigneeIds: [#{draft_issue.user_ids_github_format}],
            title: "#{draft_issue.title}",
            body: "#{draft_issue.body.gsub("\n", "\\n").gsub('"', '\"')}"
          }) {
            issue {
              id
            }
          }
        }
      GRAPHQL

      response.original_hash["data"]["createIssue"]["issue"]["id"]
    end

    def delete_draft_issue(project_id, draft_issue)
      response = client.query <<~GRAPHQL
      mutation {
        deleteProjectV2Item(input: {
          projectId: "#{project_id}",
          itemId: "#{draft_issue.id}"
        }) {
          clientMutationId
        }
      }
      GRAPHQL
    end

    def owner_is_user?(repository)
      response = client.query <<~GRAPHQL
      query {
        repositoryOwner(login: "#{repository.owner}") {
          __typename
          login
        }
      }
      GRAPHQL

      response.to_h["data"]["repositoryOwner"]["__typename"] == "User"
    end
  end

  class Converter
    def initialize(github_key)
      client = Graphlient::Client.new(
        'https://api.github.com/graphql',
        headers: {
          'Authorization' => "Bearer #{github_key}"
        },
        http_options: {
          read_timeout: 20,
          write_timeout: 30
        }
      )

      @resource_manager = GhResoucesManager.new(client)
    end

    # @param [Number] project_number
    # @param [Repository] repository
    def run(project_number, repository, interval = 25)
      repository_id = @resource_manager.fetch_repository_id(repository)
      project_id = @resource_manager.fetch_project_id(project_number, repository)

      draft_issues = @resource_manager.fetch_draft_issues(project_id)
      draft_issues.select! do |draft_issue|
        !draft_issue.unnecessary_for_convert_issue?
      end

      draft_issues.each_with_index do |draft_issue, index|
        puts "Converting: #{draft_issue.title}"

        issue_repository_id = @resource_manager.create_issue_from_draft(
          draft_issue,
          repository_id,
          project_id
        )

        puts "Add ProjectV2..."
        issue_projectv2_id = @resource_manager.add_issue_projectv2(project_id, issue_repository_id)

        puts "Update Field Values..."
        @resource_manager.update_item_field_values(project_id, draft_issue, issue_projectv2_id)

        puts "Delete DraftIssue..."
        @resource_manager.delete_draft_issue(project_id, draft_issue)

        puts "Complete Convert."

        if index == draft_issues.length - 1
          puts "All DraftIssue Converted."
        else
          # https://github.com/cli/cli/issues/4801#issuecomment-1431812916
          puts "Sleep(25s) for rate limit..."
          sleep interval
        end
      end
    end
  end
end
