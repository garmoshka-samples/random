class RandomSearch
  def initialize(params)
    @params =
        if params.is_a? ActiveRecord::Base
          RandomSearch.params_from_model(params)
        else
          params
        end
    validate # to prevent sql injections, because this class has vulnerable SQL concatenations
    send_to_elastic
    compose_compliance_pieces
  end

  def find_perfect(explain = false)
    sql = 'SELECT q.id, q.user_id,
            extract(epoch FROM q.created_at) as created_at, calc.*'
    sql += ", q.notes, #{details_fields}" if explain
    sql += " #{from} AND conflicts=0 #{order1} LIMIT 1;"
    ActiveRecord::Base.connection.execute(sql)
  end

  def find_with_conflicts
    sql = "SELECT q.id, q.safe_id, q.notes, calc.*, #{details_fields}
      #{from}
        AND #{@ages[:my_age]} >= 0 AND #{@comps[:my_gender]} >= 0
      ORDER BY conflicts DESC, score DESC, id ASC LIMIT 1;"
    ActiveRecord::Base.connection.execute(sql)
  end

  def suggestion_details(match_row)
    match_row.symbolize_keys!

    conflicts = {
        queue_sid: match_row[:safe_id],
        conflicts: -match_row[:conflicts].to_i
    }

    candidate = RandomQueue.find(match_row[:id])

    rebating_fields = [:free_talk, :real, :sexual, :video,
                       :wanted_gender, :wanted_age]
    rebating_fields.each do | f |
      if match_row[f].to_i < 0
        if f == :wanted_age
          conflicts[:age] = [candidate[:requester_age_from], candidate[:requester_age_to]]
        elsif f == :wanted_gender
          conflicts[:gender] = candidate[:requester_gender]
        else
          conflicts[f] = candidate[f]
        end
      end
    end

    conflicts
  end

  private

  def details_fields
    @comps.merge(@ages).map do |field, sql|
      "#{sql} AS #{field}"
    end.join(', ')
  end

  def order1
    # Order is:
    #   1. no conflicts
    #   2. compliance score
    #   3. oldest request
    'ORDER BY score DESC, id ASC'
  end

  def from
    q = "FROM random_queues q
        JOIN calc_compliance_sum(
          ARRAY[#{@comps.values.join(',')}],
          ARRAY[#{@ages.values.join(',')}]) calc ON (true) "

    if Rails.application.live?
      q += "LEFT JOIN (SELECT cu1.user_id
              FROM chats c
                JOIN chats_users cu2 ON (c.id=cu2.chat_id AND cu2.user_id=#{@params[:current_user][:id]})
                JOIN chats_users cu1 ON (c.id=cu1.chat_id AND NOT cu1.user_id=#{@params[:current_user][:id]})
              WHERE c.updated_at > NOW() - INTERVAL '15 minute'
            ) recent_dialogs ON (q.user_id = recent_dialogs.user_id) "
    end

    q += "WHERE NOT q.user_id = #{@params[:current_user][:id]} "

    if Rails.application.live?
      q += 'AND recent_dialogs.user_id IS NULL'
    end
    q
  end

  def compose_compliance_pieces
    # Subjects
    @comps = {}
    @params[:subjects].each do |field, value|
      @comps[field] = "subject_compliance(#{value}, #{field.to_s})"
    end

    # Gender
    @comps[:my_gender] = "my_gender_compliance('#{@params[:me][:gender]}', wanted_gender)"
    @comps[:wanted_gender] = "wanted_gender_compliance('#{@params[:look_for][:gender]}', requester_gender)"


    @ages = {}
    # My age
    my_age_from = @params[:me][:age_range][0]
    my_age_to = @params[:me][:age_range][1]
    @ages[:my_age] = "LEAST(#{my_age_to} - wanted_age_from, wanted_age_to - #{my_age_from})"

    # Wanted age
    wanted_age_from = @params[:look_for][:age_range][0]
    wanted_age_to = @params[:look_for][:age_range][1]
    @ages[:wanted_age] = "LEAST(#{wanted_age_to} - requester_age_from, requester_age_to - #{wanted_age_from})"
  end

  def self.params_from_model(model)
    {
        current_user: {id: model.user.id},
        subjects: {
            free_talk: model.free_talk,
            real: model.real,
            sexual: model.sexual,
            video: model.video
        },
        intro: model.intro,
        location: model.location,
        me: {
            gender: model.requester_gender,
            age_range: [model.requester_age_from, model.requester_age_to]
        },
        look_for: {
            gender: model.wanted_gender,
            age_range: [model.wanted_age_from, model.wanted_age_to]
        }
    }
  end

  def send_to_elastic
    Elastic.instance.log_random_request(@params)
  end

  def validate
    validate_integer @params[:current_user][:id]
    @params[:subjects].values do |value|
      validate_integer value
    end
    validate_values @params[:me][:gender], %w(m w -)
    @params[:me][:age_range].values do |value|
      validate_integer value
    end
    validate_values @params[:look_for][:gender], %w(m w -)
    @params[:look_for][:age_range].values do |value|
      validate_integer value
    end
  end
  
  def validate_integer(value)
    raise 'Validation failed' unless value.is_a? Integer
  end

  def validate_values(value, allowed)
    raise 'Validation failed' unless allowed.include? value
  end
  
end
