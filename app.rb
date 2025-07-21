require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load'

post '/ghcomment' do
  issue_url = params['text']&.strip
  channel_id = params['channel_id']
  thread_ts = params['thread_ts'] || params['message_ts']

  halt 400, "Missing thread." unless thread_ts

  messages = get_thread_messages(channel_id, thread_ts)
  thread_text = messages.map { |m| "*#{m['user'] || 'unknown'}*: #{m['text']}" }.join("\n\n")

  if issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
    org, repo, issue_number = $1, $2, $3
  else
    halt 400, "Invalid GitHub issue URL."
  end

  github_comment(issue_number, org, repo, thread_text)
end

def get_thread_messages(channel, thread_ts)
  uri = URI("https://slack.com/api/conversations.replies?channel=#{channel}&ts=#{thread_ts}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  JSON.parse(res.body)['messages'] || []
end

def github_comment(issue_number, org, repo, body)
  uri = URI("https://api.github.com/repos/#{org}/#{repo}/issues/#{issue_number}/comments")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "token #{ENV['GITHUB_TOKEN']}"
  req['Content-Type'] = 'application/json'
  req.body = { body: body }.to_json

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  halt 500, res.body unless res.code.to_i == 201
  "Posted thread to GitHub issue ##{issue_number}"
end
