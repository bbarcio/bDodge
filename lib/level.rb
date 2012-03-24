class Level
  attr_accessor :balls
  attr_accessor :level
  @@level_config = YAML::load(File.open('level_config.yml'))
#  [
#        {:from_top => 1, :duration => 20}, 
#  		{:from_top => 3, :duration => 20}, 
#  		{:from_left => 3, :duration => 20},
# 		{:from_top => 3, :from_left => 3, :duration => 20}
# 	]
  
  def initialize(game_window, player)
    @game_window = game_window
    @player = player
    @between_levels = false
    @level_delay = 3
    @level_font = Gosu::Font.new(@game_window, Gosu::default_font_name, 20)
    @level_finish_sound = Gosu::Sample.new(@game_window, "default/level_finish.mp3")	

   # @balls = 3.times.map {Ball.new(game_window, player)}
    reset
  end 
  
  def time_left
    return @time_left unless @game_window.running
  	now = Time.now
  	@time_left = (@current_config[:duration] - (now - @start_time)).round
  end
  
  def update
    #check for level end and increase level
    if (time_left > 0)
    	@balls.each {|ball| ball.update}
	else
	    @level = @level + 1 unless @between_levels
		if time_left + @level_delay < 0
		    @between_levels = false
			start_level
		else
		  @between_levels = true
		  @level_finish_sound_instance = @level_finish_sound.play unless @level_finish_sound_instance
		end
		
	end
  end
  
  def draw
    unless @between_levels
    	@balls.each {|ball| ball.draw}
	else
	  level_text = "Level #{@level + 1}"
      @level_font.draw(level_text, @game_window.width/2 - (@level_font.text_width(level_text)/2),@game_window.height/2 - (20)/2,3,1,1,@game_window.font_color)

	end
  end
  
  def start_level    
    @level_finish_sound_instance.stop if @level_finish_sound_instance
    @level_finish_sound_instance = nil
    if @level >= @@level_config.size
    	@current_config = @@level_config[@@level_config.size - 1]
    else
    	@current_config = @@level_config[@level]
    end

    #set level background color
    if @current_config[:background_color]
      @game_window.background_color = Gosu::Color.new(@current_config[:background_color])
    else
    	# if no background color specified, reset back to black
    	@game_window.background_color = MyGame::BLACK
    end
    #set font color
    if @current_config[:font_color]
      @game_window.font_color = Gosu::Color.new(@current_config[:font_color])
    else
    	# if no background color specified, reset back to black
    	@game_window.font_color = MyGame::WHITE
    end
    #set up level balls
    @balls = []
    @balls = @balls + @current_config[:from_top].times.map {Ball.new(@game_window, @player, 0, 10, lambda {rand(@game_window.width)}, lambda {0})} if @current_config[:from_top]
  	@balls = @balls + @current_config[:from_left].times.map {Ball.new(@game_window, @player, 10, 0, lambda {0}, lambda {rand(@game_window.width)})} if @current_config[:from_left]
    #set up level icons
    @balls.each {|ball| ball.icon = Gosu::Image.new(@game_window, @current_config[:ball_image], true)} if @current_config[:ball_image]
    @player.player_icon = Gosu::Image.new(@game_window, @current_config[:player_image], true) if @current_config[:player_image]
    @player.player_shield_icon = Gosu::Image.new(@game_window, @current_config[:player_shield_image], true) if @current_config[:player_shield_image]
    @player.deactivate_shield
    @player.increase_shield
    @start_time = Time.now
  end
  
  def reset
    @start_time = Time.now
  	@level = 0
  	start_level
  end
end