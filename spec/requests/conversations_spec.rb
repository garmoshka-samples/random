require 'rails_helper'
init disable_transactional_fixtures: true

describe 'Conversation', :type => :request do

  context 'between elvis and debora' do

    before do
      clean
      @elvis = create :elvis
      @debora = create :debora

      @elvis_client = SocketSub.new(@elvis.access_token)
      @deboras_client = SocketSub.new(@debora.access_token)

      @deboras_client2 =PubnubSubscriber.new
      @deboras_client2.subscribe_to_group(@debora.channel_group_name)
      @elvis_client2 =PubnubSubscriber.new
      @elvis_client2.subscribe_to_group(@elvis.channel_group_name)
    end

    it 'sends message to channel' do
      post '/messages', {
                            access_token: @debora.access_token,
                            recipient_uuid: @elvis.uuid,
                            message_text: 'hey',
                            ttl: 0
                        }
      json = parse response
      expect(json[:success]).to be true

      wait_for {
        @elvis_client.envelope && @deboras_client.envelope &&
        @elvis_client2.envelope && @deboras_client2.envelope
      }
      channel = @elvis_client.envelope['channel']

      expect(channel).to eq @elvis_client2.envelope.channel

      expect(channel).to start_with 'chat-'

      expect(@deboras_client.envelope['payload']['sender_uuid']).to eq @debora.uuid
      expect(@deboras_client.envelope['payload']['sender_idx']).to eq @debora.chat_links.first.id

      @deboras_client.reset_envelope # There came her own message
      @deboras_client2.reset_envelope # There came her own message

      post '/messages', {
                            access_token: @elvis.access_token,
                            channel: channel,
                            message_text: 'wazzup',
                            ttl: 0
                        }
      json = parse response
      expect(json[:success]).to be true
      wait_for { @deboras_client.envelope && @deboras_client2.envelope }

      expect(@deboras_client.envelope['payload']['text']).to eq 'wazzup'
      expect(@deboras_client.envelope['payload']['sender_uuid']).to eq @elvis.uuid


      expect(@deboras_client2.envelope.message['pn_apns']['message']).to eq 'wazzup'
      expect(@deboras_client2.envelope.message['sender_uuid']).to eq @elvis.uuid
    end

    it 'deleting from chat ensure silence' do
      post '/messages', {
                            access_token: @debora.access_token,
                            recipient_uuid: @elvis.uuid,
                            message_text: 'im leaving, dont look for me',
                            ttl: 0
                        }
      json = parse response
      expect(json[:success]).to be true


      wait_for {
        @elvis_client.envelope && @deboras_client.envelope
        @elvis_client2.envelope && @deboras_client2.envelope
      }
      expect(@elvis_client.envelope['payload']['sender_uuid']).to eq @debora.uuid
      channel = @elvis_client.envelope['channel']

      expect(@elvis_client2.envelope.message['sender_uuid']).to eq @debora.uuid

      @elvis_client.reset_envelope
      @deboras_client.reset_envelope
      expect(@elvis_client.got_envelope).to be false

      @elvis_client2.reset_envelope
      @deboras_client2.reset_envelope

      @elvis_client.add_event_listener :chat_empty
      delete "/chats/#{channel}/boring", access_token: @debora.access_token
      json = parse response
      expect(json[:success]).to be true

      wait_for(5) {
        @elvis_client2.envelope && @elvis_client.got_envelope
      }

      expect(@elvis_client2.envelope.message['event']).to eq 'chat_empty'
      expect(@elvis_client.envelope['payload']['sender_idx']).to eq @debora.chat_links.first.id
      expect(@elvis_client.envelope['payload']['feedback']).to eq 'boring'

      post '/messages', {
                   access_token: @elvis.access_token,
                   channel: channel,
                   message_text: 'whaaaaaayyyyy????????',
                   ttl: 0
               }
      json = parse response
      expect(json[:success]).to be false
      expect(json[:error]).to eq 'chat_empty'

      expect do
        wait_for { @deboras_client2.envelope && @deboras_client.got_envelope }
        p @deboras_client2.envelope
      end.to raise_error(WaitTimeout)

      delete "/chats/#{channel}", access_token: @elvis.access_token
      expect(Chat.find_by_channel(channel).active_users.count).to be 0
    end
  end

end
