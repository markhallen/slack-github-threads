require_relative '../test_helper'
require_relative '../../lib/services/text_processor'

class TextProcessorTest < Minitest::Test
  def test_decode_html_entities
    text = 'Hello &gt; world &lt; test &amp; more &quot;quotes&quot; and &#39;apostrophes&#39;'
    expected = 'Hello > world < test & more "quotes" and \'apostrophes\''

    result = TextProcessor.decode_html_entities(text)
    assert_equal expected, result
  end

  def test_replace_user_mentions
    text = 'Hello <@U123> and <@U456>'
    user_mentions = { 'U123' => 'John', 'U456' => 'Jane' }

    result = TextProcessor.replace_user_mentions(text, user_mentions)
    assert_equal 'Hello @John and @Jane', result
  end

  def test_replace_user_mentions_no_mentions
    text = 'Hello world'
    user_mentions = { 'U123' => 'John' }

    result = TextProcessor.replace_user_mentions(text, user_mentions)
    assert_equal 'Hello world', result
  end

  def test_replace_user_mentions_nil_mentions
    text = 'Hello <@U123>'

    result = TextProcessor.replace_user_mentions(text, nil)
    assert_equal 'Hello <@U123>', result
  end

  def test_format_message
    message = {
      'text' => 'Hello &gt; <@U123>',
      'user_name' => 'Jane Doe',
      'user_mentions' => { 'U123' => 'John' }
    }

    result = TextProcessor.format_message(message)
    assert_equal '**Jane Doe**: Hello > @John', result
  end

  def test_format_message_fallback_user
    message = {
      'text' => 'Hello world',
      'user' => 'U123'
    }

    result = TextProcessor.format_message(message)
    assert_equal '**U123**: Hello world', result
  end

  def test_format_message_unknown_user
    message = {
      'text' => 'Hello world'
    }

    result = TextProcessor.format_message(message)
    assert_equal '**unknown**: Hello world', result
  end

  def test_process_messages
    messages = [
      {
        'text' => 'First message',
        'user_name' => 'John'
      },
      {
        'text' => 'Second message',
        'user_name' => 'Jane'
      }
    ]

    result = TextProcessor.process_messages(messages)
    expected = "**John**: First message\n\n**Jane**: Second message"
    assert_equal expected, result
  end

  def test_parse_slack_thread_url_with_thread
    url = 'https://example.slack.com/archives/C1234567890/p1234567890123456?thread_ts=1234567890.123456'
    result = TextProcessor.parse_slack_thread_url(url)

    assert_equal 'C1234567890', result[:channel_id]
    assert_equal '1234567890.123456', result[:message_ts]
    assert_equal '1234567890.123456', result[:thread_ts]
  end

  def test_parse_slack_thread_url_without_thread
    url = 'https://example.slack.com/archives/C1234567890/p1234567890123456'
    result = TextProcessor.parse_slack_thread_url(url)

    assert_equal 'C1234567890', result[:channel_id]
    assert_equal '1234567890.123456', result[:message_ts]
    assert_equal '1234567890.123456', result[:thread_ts]
  end

  def test_parse_slack_thread_url_invalid
    url = 'not-a-slack-url'
    result = TextProcessor.parse_slack_thread_url(url)
    assert_nil result
  end

  def test_parse_slack_thread_url_nil
    result = TextProcessor.parse_slack_thread_url(nil)
    assert_nil result
  end
end
