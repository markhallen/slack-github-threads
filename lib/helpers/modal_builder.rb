# frozen_string_literal: true

require 'json'

class ModalBuilder
  def self.global_shortcut_modal
    {
      type: 'modal',
      callback_id: 'gh_comment_modal_global',
      title: { type: 'plain_text', text: 'Post Thread to GitHub' },
      submit: { type: 'plain_text', text: 'Post' },
      close: { type: 'plain_text', text: 'Cancel' },
      private_metadata: '{}',
      blocks: [
        {
          type: 'section',
          text: { type: 'mrkdwn',
                  text: 'To get the thread URL: Right-click on any message in the thread → *Copy link*', },
        },
        {
          type: 'input',
          block_id: 'thread_block',
          label: { type: 'plain_text', text: 'Slack Thread URL' },
          element: {
            type: 'plain_text_input',
            action_id: 'thread_url',
            placeholder: { type: 'plain_text', text: 'Paste the thread link here...' },
          },
        },
        {
          type: 'input',
          block_id: 'issue_block',
          label: { type: 'plain_text', text: 'GitHub Issue URL' },
          element: {
            type: 'plain_text_input',
            action_id: 'issue_url',
            placeholder: { type: 'plain_text', text: 'https://github.com/org/repo/issues/123' },
          },
        },
      ],
    }
  end

  def self.message_shortcut_modal(channel_id, thread_ts)
    {
      type: 'modal',
      callback_id: 'gh_comment_modal_message',
      title: { type: 'plain_text', text: 'Post Thread to GitHub' },
      submit: { type: 'plain_text', text: 'Post' },
      close: { type: 'plain_text', text: 'Cancel' },
      private_metadata: JSON.generate({
                                        channel_id: channel_id,
                                        thread_ts: thread_ts,
                                      }),
      blocks: [
        {
          type: 'section',
          text: { type: 'mrkdwn', text: 'This will post the entire thread to a GitHub issue.' },
        },
        {
          type: 'input',
          block_id: 'issue_block',
          label: { type: 'plain_text', text: 'GitHub Issue URL' },
          element: {
            type: 'plain_text_input',
            action_id: 'issue_url',
            placeholder: { type: 'plain_text', text: 'https://github.com/org/repo/issues/123' },
          },
        },
      ],
    }
  end
end
