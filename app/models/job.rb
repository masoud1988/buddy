class Job < ApplicationRecord
  belongs_to :company

  COLORS = {"Sustainability" => "#55B49E", "Consulting" => "#162a3b",
  "Artificial Intelligence" => "#33658A", "eCommerce" => "#88b2d3",
  "Video game" => "#9CD3C6"}

  def self.build_color_pie_chart(jobs)
    pie = jobs.map do |job|
      Job::COLORS[job[0]]
    end
    return pie
  end

  def self.build_color_area_chart(jobs)
    area = jobs.map do |job|
      Job::COLORS[job[0][0]]
    end
    return area.uniq
  end

  def self.build_color_priorities_pie_chart(jobs, colors_priorities)
    priorities_pie = []
    array_true_false = []

    jobs.each do |job|
      array_true_false << colors_priorities.keys.any? do |key|
        job.first.downcase.include?(key.downcase) && key.downcase != ""
      end
    end

    array_true_false.each_with_index do |element, index|
      if element == false
        priorities_pie << "#B4DAD2"
      else
        colors_priorities.each_key do |key|
          if jobs.to_a[index].first.downcase.include?(key.downcase) && key.downcase != ""
            priorities_pie << colors_priorities[key]
          end
        end
      end
    end
    return priorities_pie
  end

  def self.by_user_priorities(user, colors_priorities)
    query = <<-SQL
      select distinct jobs.* from jobs
      join companies on jobs.company_id = companies.id
      join contacts on companies.id = contacts.company_id
      join connections on contacts.id = connections.contact_id
      join users on connections.user_id = users.id
      join priorities on users.id = priorities.user_id
      where priorities.user_id = #{user.id}
    SQL

    jobs = ActiveRecord::Base.connection.execute(query)
    arr = jobs.map { |job| Job.new(job) }

    result = arr.map do |element|
      [element.title, element.created_at.strftime('%a, %d %b %Y').to_date]
    end

    hash = {}
    result.uniq.each do |element|
      colors_priorities.each_key do |key|
        if element.first.downcase.include?(key.downcase) && key.downcase != ""
          hash[element] = result.count(element)
        end
      end
    end

    comparison = hash.map do |element|
      element[0][0]
    end

    last_arr = []
    new_arr = hash.group_by_week { |u| u[0][1] }

    new_arr.each do |element_1|
      element_1[1].each do |element_2|
        last_arr << [[element_2[0][0], element_1[0]], element_2[1]]
      end
      if (comparison.uniq - element_1.flatten).length == 1
        last_arr << [[(comparison.uniq - element_1.flatten).first, element_1[0]], 0]
      elsif (comparison.uniq - element_1.flatten).length == 2
        last_arr << [[(comparison.uniq - element_1.flatten).first, element_1[0]], 0]
        last_arr << [[(comparison.uniq - element_1.flatten)[1], element_1[0]], 0]
      end
    end
    return last_arr.sort_by { |name, age| name }.to_h
  end

  def self.build_color_priorities_area_chart(jobs, colors_priorities)
    priorities_area = []
    array_true_false = []

    jobs.each do |job|
      colors_priorities.keys.any? do |key|
        if job[0][0].downcase.include?(key.downcase) && key.downcase != ""
          priorities_area << colors_priorities[key]
        end
      end
    end
    return priorities_area.uniq
  end
end
