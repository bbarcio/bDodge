class Level
  attr_accessor :balls
  attr_accessor :level
  
  def initialize(game_window, player, level_config_file = 'level_config.yml')
    @level_config = YAML::load(File.open(level_config_file))
    @game_window = game_window
    @player = player
    @between_levels = false
    @level_delay = 3
    @level_font = Gosu::Font.new(@game_window, Gosu::default_font_name, 20)
    @level_finish_sound = Gosu::Sample.new(@game_window, "default/level_finish.mp3")	
    @time_left = 0
    @ball_class = Ball#TextBall
    reset
  end 
  
  def update
    #check for level end and increase level
    if (!@between_levels &&  @time_left > 0)
      @time_left -= 1 if @game_window.running
    	@balls.each {|ball| ball.update}
    else
#      @balls = [] unless @balls.empty?
      unless @between_levels
        @level = @level + 1
        start_level
      end

      if @level_delay < 0
        @between_levels = false
        #start_level
      else
        @level_delay -= 1 if @game_window.running
      end
    end
  end
  
  def draw
    unless @between_levels
        #puts "time_left = #{@time_left}"
      unless @current_config[:level_text]
    	  @balls.each {|ball| ball.draw}
      else
        level_text = @current_config[:level_text]
        @level_font.draw(level_text, @game_window.width/2 - (@level_font.text_width(level_text)/2),@game_window.height/2 - (20)/2,3,1,1,@game_window.font_color)
      end
    else
      level_text = @current_config[:level_name] ? @current_config[:level_name] : "Level #{@level + 1}"
      @level_font.draw(level_text, @game_window.width/2 - (@level_font.text_width(level_text)/2),@game_window.height/2 - (20)/2,3,1,1,@game_window.font_color)
    end
  end
  
  def start_level    
    @level_delay = 3 * 60 #3 seconds
    @between_levels = true
    @level_finish_sound_instance = @level_finish_sound.play unless @level_finish_sound_instance

    @level_finish_sound_instance.stop if @level_finish_sound_instance
    @level_finish_sound_instance = nil
    if @level >= @level_config.size
    	@current_config = @level_config[@level_config.size - 1]
    else
    	@current_config = @level_config[@level]
    end
    configure_level(@current_config)
    @time_left = @current_config[:duration] * 60
  end
  
  def configure_level(current_config)

    #set level background color
    if current_config[:background_color]
      @background_image = nil
      @game_window.background_color = Gosu::Color.new(current_config[:background_color])
    else
    	# if no background color specified, reset back to black
    	@game_window.background_color = MyGame::BLACK
    end
    if current_config[:background_image]
        @game_window.background_image = Gosu::Image.new(@game_window, current_config[:background_image], true)
    end

    #set font color
    if current_config[:font_color]
      @game_window.font_color = Gosu::Color.new(current_config[:font_color])
    else
    	# if no background color specified, reset back to black
    	@game_window.font_color = MyGame::WHITE
    end
    #set music
    if current_config[:music]
      play_music = true if @game_window.music.playing?
      @game_window.music = Gosu::Song.new(@game_window, current_config[:music])
      @game_window.music.play(true) if play_music
    end
    if current_config[:ball_type]
      @ball_class = Kernel.const_get current_config[:ball_type]
    end

    #set up level balls
    @balls = []
    @balls = @balls + current_config[:from_top].times.map {@ball_class.new(@game_window, @player, 0, current_config[:yinc] ? current_config[:yinc] : 10, lambda {rand(@game_window.width)}, lambda {0})} if current_config[:from_top]
  	@balls = @balls + current_config[:from_left].times.map {@ball_class.new(@game_window, @player, current_config[:xinc] ? current_config[:xinc] : 10, 0, lambda {0}, lambda {rand(@game_window.height)})} if current_config[:from_left]
    @balls = @balls + current_config[:from_bottom].times.map {@ball_class.new(@game_window, @player, 0, current_config[:yinc] ? current_config[:yinc] : -10, lambda {rand(@game_window.width)}, lambda {@game_window.height})} if current_config[:from_bottom]
  	@balls = @balls + current_config[:from_right].times.map {@ball_class.new(@game_window, @player, current_config[:xinc] ? current_config[:xinc] : -10, 0, lambda {@game_window.width}, lambda {rand(@game_window.height)})} if current_config[:from_right]
  	@balls = @balls + current_config[:from_custom][:count].times.map {@ball_class.new(@game_window, @player, eval(current_config[:from_custom][:xinc]), eval(current_config[:from_custom][:yinc]),
  	    eval(current_config[:from_custom][:xinit]),  eval(current_config[:from_custom][:yinit]))} if current_config[:from_custom]    
    #set up level icons
    @balls.each {|ball| ball.icon = Gosu::Image.new(@game_window, current_config[:ball_image], true)} if current_config[:ball_image]
    @balls.each {|ball| ball.set_config current_config[:ball_config] } if current_config[:ball_config]
    @player.player_icon = Gosu::Image.new(@game_window, current_config[:player_image], true) if current_config[:player_image]
    @player.player_shield_icon = Gosu::Image.new(@game_window, current_config[:player_shield_image], true) if current_config[:player_shield_image]
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