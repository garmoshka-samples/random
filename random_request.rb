class RandomRequest < Mutations::Command

  required do
    model :user
    duck :params
  end

  def validate
    user.detect_vegetable
    if Rails.application.live? && user.score < 5
      # Deny access for too passive users
      add_error(:user, :vegetable, 'No access for vegetables')
    end
  end

  def execute
    cancel_previous_requests

    matches = RandomSearch.new(params).find_perfect
    if matches.count > 0
      m = matches.first
      partner = User.find(m['user_id'])

      create_conversation partner,
          talk_params(user, params,
                      partner, params_from_id(m['id']),
                      m['created_at'])

      partner.random_queues.destroy_all
    else
      RandomQueue.create_from_request(params)
    end
  end

  private

  def talk_params(a_user, a_params,
          b_user, b_params, b_created)
      {
          a: {
              client_id: a_user.uuid,
              level: a_user.score,
              honor: a_user.honor,
              request_created_ms: (Time.now.to_f * 1000).round,
              preferences: sanitize(a_params)
          },
          b: {
              client_id: b_user.uuid,
              level: b_user.score,
              honor: b_user.honor,
              request_created_ms: (b_created.to_i * 1000).round,
              preferences: sanitize(b_params)
          }
      }
  end

  def sanitize(params)
    params.delete :current_user
    params
  end

  def cancel_previous_requests
    user.random_queues.delete_all
  end

  def create_conversation(partner, talk_params)
    chat = Chat.create_for(user, partner)
    payload = {profiles: {}}
    chat.user_links.each do |link|
      u = link.user
      payload[:profiles][link.id] = {
          avatar_url: u.avatar_url,
          avatar_guid: u.avatar_guid,
          honor: u.honor
      }
    end
    Message::ChatBroadcasting.run(event: :chat_ready,
                                  chat: chat, delay_s: 1,
                                  payload: payload,
                                  talk_params: talk_params)
    chat
  end

  def params_from_id(id)
    RandomSearch.params_from_model RandomQueue.find(id)
  end

end