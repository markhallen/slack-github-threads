# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class GitHubService
  API_BASE = 'https://api.github.com'

  def initialize(token, debug: false, logger: nil)
    @token = token
    @debug = debug
    @logger = logger
  end

  def debug_log(message)
    puts message if @debug
    @logger&.debug(message)
  end

  def create_comment(org, repo, issue_number, body)
    uri = URI("#{API_BASE}/repos/#{org}/#{repo}/issues/#{issue_number}/comments")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "token #{@token}"
    req['Content-Type'] = 'application/json'
    req.body = { body: body }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.code.to_i == 201
      puts 'GitHub POST failed:'
      puts "URL: #{uri}"
      puts "Status: #{res.code} #{res.message}"
      puts "Body: #{res.body}"
      puts "Request: #{req.body}"
      raise "GitHub error: #{res.body}"
    end

    # Parse the response to get the comment URL
    comment_data = JSON.parse(res.body)
    comment_url = comment_data['html_url']

    debug_log "DEBUG: Successfully posted to GitHub issue ##{issue_number}, comment URL: #{comment_url}"
    comment_url
  end

  def self.parse_issue_url(url)
    return nil unless url

    match = url.match(%r{github\.com/([^/]+)/([^/]+)/issues/(\d+)})
    return nil unless match

    {
      org: match[1],
      repo: match[2],
      issue_number: match[3],
    }
  end
end
