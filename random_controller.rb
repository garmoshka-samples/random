class RandomController < ApplicationController

  def do_request
    current_user.save_request_ip
    RandomRequest.run(user: current_user,
                      params: request_params)
    render json: action_succeeded_message(score: current_user.reload.score)
  end

  def cancel
    current_user.random_queues.delete_all
    render json: action_succeeded_message
  end

  private

  def request_params
    params.permit(
      :intro,
      :location,
      subjects: [:free_talk, :real, :sexual, :video],
      me: [:gender, :age_range => []],
      look_for: [:gender, :age_range => []]
    ).merge({ current_user: current_user })
  end
end
