class RandomQueue < ActiveRecord::Base
  include WithSafeId

  belongs_to :user

  def self.create_from_request(params)
    create(
      user_id: params[:current_user].id,

      free_talk: params[:subjects][:free_talk] || 0,
      real: params[:subjects][:real]  || 0,
      sexual: params[:subjects][:sexual]  || 0,
      video: params[:subjects][:video]  || 0,

      intro: params[:intro],
      location: params[:location],

      requester_gender: params[:me][:gender],
      requester_age_from: params[:me][:age_range][0],
      requester_age_to: params[:me][:age_range][1],

      wanted_gender: params[:look_for][:gender],
      wanted_age_from: params[:look_for][:age_range][0],
      wanted_age_to: params[:look_for][:age_range][1]

      #is_locked: params[:is_locked]
    )
  end
end
