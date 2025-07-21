require_relative '../test_helper'
require_relative '../../lib/services/github_service'

class GitHubServiceTest < Minitest::Test
  def setup
    super
    @service = GitHubService.new('test-token')
  end

  def test_create_comment_success
    stub_github_create_comment('owner', 'repo', '1')

    result = @service.create_comment('owner', 'repo', '1', 'Test comment body')
    
    assert_equal 'https://github.com/org/repo/issues/1#issuecomment-123', result
  end

  def test_create_comment_failure
    stub_request(:post, "https://api.github.com/repos/owner/repo/issues/1/comments")
      .to_return(
        status: 404,
        body: { message: 'Not Found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_raises RuntimeError do
      @service.create_comment('owner', 'repo', '1', 'Test comment body')
    end
  end

  def test_parse_issue_url_success
    url = 'https://github.com/owner/repo/issues/123'
    result = GitHubService.parse_issue_url(url)
    
    assert_equal 'owner', result[:org]
    assert_equal 'repo', result[:repo]
    assert_equal '123', result[:issue_number]
  end

  def test_parse_issue_url_with_trailing_content
    url = 'https://github.com/owner/repo/issues/123#issuecomment-456'
    result = GitHubService.parse_issue_url(url)
    
    assert_equal 'owner', result[:org]
    assert_equal 'repo', result[:repo]
    assert_equal '123', result[:issue_number]
  end

  def test_parse_issue_url_invalid
    result = GitHubService.parse_issue_url('not-a-github-url')
    assert_nil result
  end

  def test_parse_issue_url_nil
    result = GitHubService.parse_issue_url(nil)
    assert_nil result
  end

  def test_parse_issue_url_pull_request
    url = 'https://github.com/owner/repo/pull/123'
    result = GitHubService.parse_issue_url(url)
    assert_nil result
  end
end
