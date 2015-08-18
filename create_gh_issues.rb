require 'dotenv'
require 'octokit'
require 'pivotal_tracker'

Dotenv.load

gh_client = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])

PivotalTracker::Client.token = ENV['PIVOTAL_API_TOKEN']

ENV['PIVOTAL_PROJECTS'].split(',').map(&:to_i).each do |project_id|
  i = 0
  PivotalTracker::Project.find(project_id).stories.all.reverse.each do |story|
    summary = "[project: #{project_id}, story: #{story.id}]"

    if story.current_state == 'accepted'
      puts "#{summary} skip export(closed)"
      next
    end

    puts "#{summary} to #{ENV['GITHUB_REPO']}"

    title = story.name
    body = story.description.dup << "\n\n" << story.notes.all.map(&:text).join("\n\n")
    gh_client.create_issue(ENV['GITHUB_REPO'], title, body, labels: story.labels)
  end
end
