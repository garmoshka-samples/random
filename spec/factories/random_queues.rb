FactoryGirl.define do

  factory :queued_request, class: RandomQueue do
    notes 'queued_request'
    free_talk 0
    real 0
    sexual 0
    video 0

    intro ''
    location ''

    requester_gender '-'
    requester_age_from 0
    requester_age_to 100

    wanted_gender '-'
    wanted_age_from 0
    wanted_age_to 100

    factory :req_of_girl_with_video_deny do
      notes 'req_of_girl_with_video_deny'
      video -1

      requester_gender 'w'
      requester_age_from 18
      requester_age_to 21

      wanted_gender 'm'
      wanted_age_from 22
      wanted_age_to 25
    end

    factory :req_of_ahmed do
      notes 'req_of_ahmed'
      intro 'Bistro bistro'

      free_talk -1
      real 2
      video 1

      requester_gender 'm'
      requester_age_from 22
      requester_age_to 25

      wanted_gender 'w'
      wanted_age_from 21
      wanted_age_to 100
    end

    factory :req_of_teenage_girl do
      notes 'req_of_teenage_girl'
      intro '^^'

      sexual 1
      video -1

      requester_gender 'w'
      requester_age_from 0
      requester_age_to 17

      wanted_gender 'm'
      wanted_age_from 0
      wanted_age_to 22
    end

    factory :req_of_glamour_girl do
      notes 'req_of_glamour_girl'
      free_talk -1

      requester_gender 'w'
      requester_age_from 22
      requester_age_to 25
    end

    factory :req_of_teenage_boy do
      notes 'req_of_teenage_boy'
      sexual 1
      video 1

      requester_gender 'm'
      requester_age_from 18
      requester_age_to 21

      wanted_gender 'w'
      wanted_age_from 0
      wanted_age_to 25
    end

    factory :req_of_hungry_guy do
      notes 'req_of_hungry_guy'

      sexual 2
      video 2

      requester_gender 'm'
      requester_age_from 18
      requester_age_to 21

      wanted_gender 'w'
      wanted_age_from 0
      wanted_age_to 100
    end

    factory :req_of_pedobear do
      notes 'req_of_pedobear'
      sexual 2
      video 2

      intro 'where is my honey?'

      requester_gender 'M'
      requester_age_from 36
      requester_age_to 100

      wanted_gender '-'
      wanted_age_from 0
      wanted_age_to 15
    end

    factory :req_of_johnny_bravo do
      notes 'req_of_johnny_bravo'
      intro 'Enough about you, lets talk about me'

      free_talk 1
      sexual 1

      requester_gender 'm'
      requester_age_from 26
      requester_age_to 35

      wanted_gender 'w'
      wanted_age_from 18
      wanted_age_to 35
    end

    factory :req_of_requester_stub do
      notes 'req_of_requester_stub'
      intro ''

      free_talk 0
      real 0
      sexual 0
      video 0

      requester_gender '-'
      requester_age_from 0
      requester_age_to 100

      wanted_gender '-'
      wanted_age_from 0
      wanted_age_to 100
    end

  end
end