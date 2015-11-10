require 'rails_helper'
init

describe RandomController, type: :controller do

  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  before(:each) do
    @elvis = create :elvis
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
  end

  context 'empty queue' do
    before(:each) do
      authenticate request, @elvis.access_token
      post :do_request, @elvis_default_request
    end

    it 'queues request' do
      expect(json[:success]).to be true
      expect(@elvis.random_queues.count).to be 1
    end

    it 'revokes request' do
      delete :cancel, access_token: @elvis.access_token
      expect(json[:success]).to be true
      expect(@elvis.random_queues.count).to be 0
    end

    it 'user score' do
      expect(json[:score]).to be 10
    end
  end

  context 'with Debora in queue' do
    before(:each) do
      @debora = create :user, name: 'Debora'
      create :req_of_girl_with_video_deny, user: @debora
    end

    it 'queues req non-matching by age' do
      post :do_request,
           @elvis_default_request.merge(look_for: {age_range: [22, 100]})
      expect_queued
    end

    it 'queues non-matching by necessary video' do
      post :do_request, @elvis_default_request.merge(video: 2)
      expect_queued
    end

    it 'queues even more non-matching request' do
      post :do_request,
           @elvis_default_request.merge(
              video: 2, look_for: {age_range: [22, 100]}
           )
      expect_queued
    end

    let (:expect_queued) {
      expect(json[:success]).to be true
      expect(@elvis.random_queues.count).to be 1
      expect(@elvis.chats.count).to be 0
    }
  end

end
