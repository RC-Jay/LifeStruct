class GoalsController < ApplicationController

  def index
    @goals = Goal.all
    @root_goals = Goal.root_goals
  end

  def show
    @goal = Goal.find(params[:id])
  end

  def assign
    Goal.assign_goals
    redirect_to '/home'   
  end

  def destroy
    @del_goal = Goal.find(params[:id])
    @sub_goals = @del_goal.subgoals
    @sub_goals.each do |subgoal|
      if subgoal.goal_map
        subgoal.goal_map.destroy
      end
      subgoal.destroy
    end
    @del_goal.goal_map.destroy if @del_goal.goal_map
    @del_goal.destroy
    redirect_to '/goals'
  end
  
  def create
    #render text: params
    #return
    @new_goal = Goal.new
    title = goal_params[:title]
    description = goal_params[:description]
    deadline = stringify_date(goal_params[:"deadline(1i)"], goal_params[:"deadline(2i)"], goal_params[:"deadline(3i)"], goal_params[:"deadline(4i)"], goal_params[:"deadline(5i)"])
    starttime = stringify_date(goal_params[:"starttime(1i)"], goal_params[:"starttime(2i)"], goal_params[:"starttime(3i)"], goal_params[:"starttime(4i)"], goal_params[:"starttime(5i)"])
    endtime =  stringify_date(goal_params[:"endtime(1i)"], goal_params[:"endtime(2i)"], goal_params[:"endtime(3i)"], goal_params[:"endtime(4i)"], goal_params[:"endtime(5i)"]) 
    repeatable = goal_params[:repeatable].to_i
    hardcode_time = goal_params[:hardcode_time].to_i
    monday_stat = goal_params[:repeat1]
    tuesday_stat = goal_params[:repeat2]
    wednesday_stat = goal_params[:repeat3]
    thursday_stat = goal_params[:repeat4]
    friday_stat = goal_params[:repeat5]
    saturday_stat = goal_params[:repeat6]
    sunday_stat = goal_params[:repeat7]
    month_stat = goal_params[:repeat8]
    all_stats = [monday_stat, tuesday_stat, wednesday_stat, thursday_stat, friday_stat, saturday_stat, sunday_stat, month_stat]
    parent_id = goal_params[:parent_id]

    if parent_id.empty?
      parent_id = nil
    else
      parent_id = parent_id.to_i
      Goal.find(parent_id).update_attribute(:has_child, 1)
    end

    if hardcode_time == 1
      deadline = nil
    else
      starttime = nil
      endtime = nil
      time_alloc = goal_params[:allocate_minutes]
    end

    repeat_stat = nil
    if repeatable == 1
      rep_string = ""
      all_stats.each_with_index do |stat, index|
        if stat == "1"
          rep_string += (index + 1).to_s
        end
      end
      repeat_stat = rep_string.to_i
    end

    @new_goal.assign_attributes({title: title,
       description: description,
       deadline: deadline,
       start: starttime,
       repeatable: repeat_stat,
       :end => endtime,
       parent_id: parent_id,
       timetaken: time_alloc
      })
    @new_goal.save
    unless @new_goal.timetaken
      time_taken = (@new_goal.end.to_time - @new_goal.start.to_time)/60
      @new_goal.update_attribute(:timetaken, time_taken)
    end
    redirect_to goals_path
  end

  def string_to_datetime(year, month, day, hour, min)
    DateTime.new(year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i).change(offset: "+0530")
  end

  def freetime
    starttime = string_to_datetime(goal_params[:"starttime(1i)"], goal_params[:"starttime(2i)"], goal_params[:"starttime(3i)"], goal_params[:"starttime(4i)"], goal_params[:"starttime(5i)"])
    endtime =  string_to_datetime(goal_params[:"endtime(1i)"], goal_params[:"endtime(2i)"], goal_params[:"endtime(3i)"], goal_params[:"endtime(4i)"], goal_params[:"endtime(5i)"]) 
    displaced_goals = Goal.free_time_between(starttime, endtime)
    displaced_goals.each {|goal| 
      (endtime..goal.deadline).each do |date|
        puts "DATE KA TOp KEEK : #{date}"
      end   
      goal.assign({status: "fluid", date_range: (endtime..goal.deadline)})
    }
    redirect_to '/home'
  end

  def stringify_date(year, month, day, hour, min)
    datetime = "#{year}-#{month}-#{day} #{hour}:#{min}"
  end

  def calendar
    @asgn_goals = []
    start_date = build_date_from_date_string(params[:start])
    fin_date = build_date_from_date_string(params[:end])
    GoalMap.all.map{ |gm| gm.goal }.each do |goal|
      if goal.repeatable
        goals = goal.all_reps_in_bw(start_date, fin_date)
        goals.each do |goal|
          goal.start = goal.start.to_s
          goal.end = goal.end.to_s
        end
        @asgn_goals.push(goals)
      else
        goal.start = goal.start.to_s
        goal.end = goal.end.to_s
        @asgn_goals.push(goal)
      end
    end
    @asgn_goals.flatten!
    respond_to do |format|
      format.json
      format.html
    end
  end

  def build_date_from_date_string(date_string)
    if date_string.present?
      date_array = date_string.split('-').map{|date_str| date_str.to_i}
      return Date.new(*date_array) # Flatten the array and pass to Date.new
    end
  end

  def show_subgoals
    goal_parent_id = params[:parentid]
    @ul_con = "#ul-parent-#{goal_parent_id}"
    @show_sg_icn_path = "#show-parent-#{goal_parent_id} i"
    @subgoals = Goal.find(goal_parent_id).subgoals
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def goal_params
    params.require(:goal).permit(:allocate_minutes, :title, :description, :"deadline(1i)", :"deadline(2i)", :"deadline(3i)", :"deadline(4i)", :"deadline(5i)", :"starttime(1i)", :"starttime(2i)", :"starttime(3i)", :"starttime(4i)", :"starttime(5i)", :"endtime(1i)", :"endtime(2i)", :"endtime(3i)", :"endtime(4i)", :"endtime(5i)", :repeatable, :hardcode_time, :repeat1, :repeat2, :repeat3, :repeat4, :repeat5, :repeat6, :repeat7, :repeat8, :deadline, :parent_id)
  end

end
