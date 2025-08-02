class TextProcessor
  HTML_ENTITIES = {
    '&gt;' => '>',
    '&lt;' => '<',
    '&amp;' => '&',
    '&quot;' => '"',
    '&#39;' => "'"
  }.freeze

  def self.process_messages(messages)
    messages.map { |m| format_message(m) }.join("\n\n")
  end

  def self.format_message(message)
    text = message['text'] || ''

    # Decode HTML entities
    text = decode_html_entities(text)

    # Replace user mentions with actual names
    text = replace_user_mentions(text, message['user_mentions'])

    # Use real name if available, otherwise fall back to user ID
    user_display = message['user_name'] || message['user'] || 'unknown'

    "**#{user_display}**: #{text}"
  end

  def self.decode_html_entities(text)
    HTML_ENTITIES.each do |entity, replacement|
      text = text.gsub(entity, replacement)
    end
    text
  end

  def self.replace_user_mentions(text, user_mentions)
    return text unless user_mentions

    original_text = text.dup
    user_mentions.each do |user_id, user_name|
      if text.include?("<@#{user_id}>")
        puts "DEBUG: Replacing <@#{user_id}> with @#{user_name}"
        text = text.gsub("<@#{user_id}>", "@#{user_name}")
      end
    end

    if original_text != text
      puts "DEBUG: Text changed from '#{original_text}' to '#{text}'"
    end

    text
  end

  def self.parse_slack_thread_url(url)
    return nil unless url

    match = url.match(%r{https://[\w-]+\.slack\.com/archives/([^/]+)/p(\d+)(?:\?thread_ts=(\d+\.\d+))?})
    return nil unless match

    {
      channel_id: match[1],
      message_ts: "#{match[2][0..-7]}.#{match[2][-6..-1]}",
      thread_ts: match[3] || "#{match[2][0..-7]}.#{match[2][-6..-1]}"
    }
  end
end
