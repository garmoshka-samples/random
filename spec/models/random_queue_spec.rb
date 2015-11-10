require 'rails_helper'
init

# Option: Each time clear DB & leave test records there
# to have ability analyze data in tables from DB viewer
DB_ANALYST_MODE = false

RSpec.configure do |config|
  config.use_transactional_fixtures = !DB_ANALYST_MODE
end

describe RandomQueue, type: :model do

  context 'johnny bravo hunting' do

    before :each do
      User.clean if (DB_ANALYST_MODE)
      @johnny = create :user
      @johnny_req = build :req_of_johnny_bravo, user: @johnny
    end

    context 'full queue' do
      before :each do
        RandomQueue.destroy_all if (DB_ANALYST_MODE)

        create :queued_request, user: (create :user)
        create :req_of_girl_with_video_deny , user: (create :user)
        create :req_of_teenage_girl, user: (create :user)
        create :req_of_glamour_girl, user: (create :user)
        create :req_of_teenage_boy, user: (create :user)
        create :req_of_hungry_guy, user: (create :user)
        create :req_of_pedobear, user: (create :user)
        #create :req_of_johnny_bravo , user: (create :user)
      end

      it 'connects with glamour_girl' do
        matches = RandomSearch.new(@johnny_req).find_perfect true

        expect(matches.count).to be > 0
        m = matches[0].symbolize_keys!
        expect(m[:notes]).to eq 'req_of_glamour_girl'
        expect(m[:score]).to eq '6'
        expect(m[:free_talk]).to eq '0'
        expect(m[:real]).to eq '2'
        expect(m[:wanted_age]).to eq '7'
      end
    end

    context 'one request with unspecified gender' do
      before :each do
        RandomQueue.destroy_all if (DB_ANALYST_MODE)

        create :queued_request, user: (create :user)
      end

      it 'cant find perfect match' do
        matches = RandomSearch.new(@johnny_req).find_perfect
        expect(matches.count).to eq 0
      end

      it 'connects with conflicted' do
        search = RandomSearch.new(@johnny_req)
        matches = search.find_with_conflicts
        expect(matches.count).to eq 1

        details =  search.suggestion_details matches[0]
        expect(details[:conflicts]).to eq 1
        expect(details[:gender]).to eq '-'
      end
    end
  end

  context 'ahmed hunting' do

    before do
      User.clean if (DB_ANALYST_MODE)
      @ahmed = create :user
      @ahmed_req = build :req_of_ahmed, user: @ahmed
    end

    context 'one girl_with_video_deny' do
      before do
        RandomQueue.destroy_all if (DB_ANALYST_MODE)

        @debora = create :user, name: 'Debora'
        create :req_of_girl_with_video_deny, user: @debora
      end

      it 'do not connect because real subject does not present' do
        matches = RandomSearch.new(@ahmed_req).find_perfect true
        expect(matches.count).to be 0
      end

      it 'connects if reduce real requirements' do
        @ahmed_req.real = 1
        matches = RandomSearch.new(@ahmed_req).find_perfect true

        expect(matches.count).to be 1
        m = matches[0].symbolize_keys!
        expect(m[:notes]).to eq 'req_of_girl_with_video_deny'
        expect(m[:score]).to eq '6'
        expect(m[:free_talk]).to eq '1'
        expect(m[:real]).to eq '1'
        expect(m[:wanted_age]).to eq '0'
        expect(m[:my_age]).to eq '3'
      end
    end
  end
end
