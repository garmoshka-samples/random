FactoryGirl.define do
  factory :user do
    name { generate(:name) }
    phone_number { generate(:phone) }

    factory :elvis do
      name 'Elvis Ulan Bade'
      access_token 'elvis-token'
    end

    factory :debora do
      name 'Debora Walley'
      access_token 'debora-token'
      association :image, factory: :girl_avatar
      avatar_guid 'deboras-ava-guid'
    end

    factory :ron do
      name 'Ronald McDonald'
    end

    factory :system do
      name 'system'
      access_token 'system-token'
    end

    factory :party_promoter do
      name 'Party promoter'
      phone_number '+79169000000'
    end

    factory :friend do
      phone_number '+79153214567'
    end

    factory :admin do
      data '{"is_admin": true}'
    end

    factory :virtual do
      name 'virtual'
      password 'password'
      is_virtual true
    end
  end

  sequence :name do |n|
    "Jack#{n}"
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :phone do |n|
    "+790#{n}"
  end
end
