require 'rails_helper'
init disable_transactional_fixtures: true

describe 'Random chatting', :type => :request do

  context 'having Debora in queue' do

    before do
      clean

      @elvis = create :elvis
      @default_request = {
          format: :json,
          subjects: {free_talk: 0, real: 0, video: 0},
          me: {
              gender: '-',
              age_range: [0, 100]
          },
          look_for: {
              gender: '-',
              age_range: [0, 100]
          }
      }
      @elvis_default_request = {
          format: :json,
          access_token: @elvis.access_token,

          subjects: {
              free_talk: -1,
              real: 2,
              video: 1
          },
          intro: 'Get up everybody!',
          location: 'Az',
          me: {
              gender: 'm',
              age_range: [22, 25]
          },
          look_for: {
              gender: 'w',
              age_range: [21, 100]
          }
      }

      @elvis_client = SocketSub.new(@elvis.access_token)
      @elvis_client.add_event_listener :chat_ready

      @elvis_client2 = PubnubSubscriber.new
      @elvis_client2.subscribe_to_group(@elvis.channel_group_name)

      @debora = create :debora
      create :req_of_girl_with_video_deny, user: @debora

      @deboras_client = SocketSub.new(@debora.access_token)
      @deboras_client.add_event_listener :chat_ready

      @deboras_client2 = PubnubSubscriber.new
      @deboras_client2.subscribe_to_group(@debora.channel_group_name)
    end

    it 'chatting with matched person and connect again only after 15 min' do
      Rails.application.secrets.live = 'true'

      expect(@debora.random_queues.count).to be 1

      elvis_request = @elvis_default_request.merge(subjects: {real: 1})

      post '/random', elvis_request
      json = parse response
      expect(json[:success]).to be true
      expect(@elvis.random_queues.count).to be 0
      expect(@debora.random_queues.count).to be 0

      wait_for do
        @elvis_client.got_envelope && @deboras_client.got_envelope &&
        @elvis_client2.envelope && @deboras_client2.envelope
      end

      e = @deboras_client.envelope
      pf = e['payload']['profiles'][e['my_idx'].to_s]
      expect(pf['avatar_guid']).to eq 'deboras-ava-guid'
      expect(pf['honor']).to eq 1

      @deboras_client.reset_envelope
      @deboras_client2.reset_envelope


      post '/messages', {
                            access_token: @elvis.access_token,
                            channel: @elvis_client.envelope['channel'],
                            message_text: 'come on come on',
                            ttl: 0
                        }
      json = parse response
      expect(json[:success]).to be true

      wait_for { @deboras_client.envelope }

      expect(@deboras_client.envelope['payload']['sender_uuid']).to eq @elvis.uuid
      expect(@deboras_client.envelope['payload']['text']).to eq 'come on come on'

      post '/messages', {
                          access_token: @debora.access_token,
                          channel: @deboras_client.envelope['channel'],
                          message_text: 'hey, i need to go',
                          ttl: 0
                      }

      delete '/chats/' + @deboras_client.envelope['channel'], access_token: @debora.access_token

      create :req_of_girl_with_video_deny, user: @debora
      post '/random', elvis_request

      expect(@elvis.random_queues.count).to be 1
      expect(@debora.random_queues.count).to be 1
      expect(@elvis.chats.count).to be 1

      delete '/random', access_token: @elvis.access_token

      # imitate 16 min passed
      @elvis.chats.first.update updated_at: DateTime.now - 16.minutes

      post '/random', elvis_request
      expect(@elvis.random_queues.count).to be 0
      expect(@debora.random_queues.count).to be 0
      expect(@elvis.chats.count).to be 2
    end

    it 'reset scores of silent partner' do
      Rails.application.secrets.live = 'true'
      post '/random', @elvis_default_request.merge(subjects: {real: 1})
      wait_for do
        @elvis_client.got_envelope && @deboras_client.got_envelope
      end

      @deboras_client.reset_envelope

      post '/messages', {
                          access_token: @elvis.access_token,
                          channel: @elvis_client.envelope['channel'],
                          message_text: 'hey, lets talk bout vegetables',
                          ttl: 0
                      }
      wait_for { @deboras_client.envelope }
      # imitate long chat
      @elvis.chats.first.update duration: 333

      post '/random', @default_request.merge(
                      {access_token: @debora.access_token,
                       location: 'garden'})

      # vegetable should be detected:
      @debora.reload
      expect(@debora.random_queues.count).to be 0
      expect(@debora.score).to be 1
    end

  end

end