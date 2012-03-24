require 'rubygems'
require 'gosu'
require 'yaml'
#pond5.com to purchase? media royalty free
class MyGame < Gosu::Window
  attr_reader :running
  attr_accessor :background_color
  attr_accessor :font_color
  PADDING = 10
  BLACK = Gosu::Color.new(0xff000000)
  WHITE = Gosu::Color.new(0xffffffff)
  def initialize
    super(800, 800, false)
    @player1 = Player.new(self)
    @level = Level.new(self, @player1)
    @running = true
    @paused = false
    self.caption = "bDodge"
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @highscores = YAML::load(File.open 'highscores.yml')
    @background_color = BLACK
    @font_color = WHITE
    @death_sound = Gosu::Sample.new(self, "default/death.mp3")
    @music = Gosu::Song.new(self, "default/bSong1.mp3")
  	#@music.play(true)
  end

  def update
    if @running
        @player1.update
        @level.update
        if @player1.hit_by? @level.balls
          @death_sound.play
          stop_game!
        end
    else
      # the game is currently stopped
      if button_down? Gosu::Button::KbEscape
        restart_game
      end
    end
  end

  def draw
    draw_quad(0, 0, @background_color, width, 0, @background_color, 
    	0, height, @background_color, width, height, @background_color)
    @player1.draw
    @level.draw
    score_text = "Score: #{@player1.score}"
    @font.draw(score_text, width - (@font.text_width(score_text)+PADDING),PADDING,3,1,1,@font_color)
    highscore_text = "Highscore: #{@highscores[0][:score]}"
    @font.draw(highscore_text, width/2 - (@font.text_width(highscore_text)/2),PADDING,3,1,1,@font_color)
    level_text = "Level #{@level.level + 1} (#{@level.time_left < 0 ? 0 : @level.time_left})"
    @font.draw(level_text, PADDING,PADDING,3,1,1,@font_color)
    if @player1.shield?
    	shield_text = "Shield Remaining #{@player1.shield_time_left}"
    	@font.draw(shield_text,  width/2 - (@font.text_width(shield_text)/2),height/2 - (20)/2,3,1,1,@font_color)
	end
	shield_text = "Shield: #{@player1.shield_count}"
    @font.draw(shield_text, PADDING, height - (20 + PADDING),3,1,1,@font_color)
	
    unless @running
      restart_text = "Hit 'esc' to restart"
      @font.draw(restart_text, width/2 - (@font.text_width(restart_text)/2),height/2 - (20)/2-50,3,1,1,@font_color)
      highscore_text = "Highscores"

      @font.draw(highscore_text, width/2 - (@font.text_width(highscore_text)/2),height/2 - (20)/2,3,1,1,@font_color)
      nextline = 30
      @highscores.each do |h| 
        highscore_text = h[:name] + ': ' + h[:score].to_s
        @font.draw(highscore_text, width/2 - (@font.text_width(highscore_text)/2),height/2 - (20)/2 + nextline,3,1,1,@font_color)
        nextline = nextline + 30
      end
    end
    
  end

  def stop_game!
    @running = false
    if @player1.score > @highscores[4][:score]
   	  @highscores[4][:score] = @player1.score 
      @highscores.sort! {|a,b| b[:score] <=> a[:score]}
      f = File.open('highscores.yml', 'w+')
      f.write(@highscores.to_yaml)
      f.close
    end
  end

  def restart_game
    @running = true
    @player1.reset
    @level.reset
  end
end

class Player
  HIT_BUFFER = 30
  CLOSE_BUFFER = -60
  SHIELD_LENGTH = 3
  attr_reader :shield_count
  attr_accessor :player_icon, :player_shield_icon
  def initialize(game_window)
    @game_window = game_window
    @player_icon = Gosu::Image.new(@game_window, "default/player1.png", true)
    @player_shield_icon = Gosu::Image.new(@game_window, "default/player1_neon.jpg", true)
    @icon = @player_icon
    @close_sound = Gosu::Sample.new(@game_window, "default/close_shave.mp3")	
    @shield_sound = Gosu::Sample.new(@game_window, "default/shield.mp3")	
	reset
  end

  def score
    @score
  end

  def reset
    @x = @game_window.width/2 - @icon.width/2
    @y = @game_window.height - @icon.height
    @score = 0
    @shield = false
    @shield_count = 0
    @shield_time = Time.now
    @shield_time_left = 0
  end
  
  def increase_score
    @score = @score + 10
  end
  
  def draw
    @icon.draw(@x,@y,1)
  end

  def update
      if @game_window.button_down? Gosu::Button::KbSpace
        activate_shield
      end
      
      if @game_window.button_down? Gosu::Button::KbLeft
        move_left
      end

      if @game_window.button_down? Gosu::Button::KbRight
        move_right
      end

      if @game_window.button_down? Gosu::Button::KbUp
        move_up
      end

      if @game_window.button_down? Gosu::Button::KbDown
        move_down
      end
	unless (shield_time_left > 0 )
	  deactivate_shield
	end
  end
  
  def move_left
    if @x < 0
      @x = 0
    else
      @x = @x - 10
    end
  end

  def move_right
    if @x > (@game_window.width - @icon.width)
      @x = @game_window.width - @icon.width
    else
      @x = @x + 10
    end
  end

  def move_up 
    if @y < 0
      @y = 0
    else
      @y = @y - 10
    end
  end
 
  def move_down
    if @y > (@game_window.height - @icon.height)
      @y = @game_window.height - @icon.height
    else
      @y = @y + 10
    end
  end

  def activate_shield
    unless @shield || @shield_count == 0
        @shield_count = @shield_count - 1
  		@shield = true
  		@shield_time = Time.now
  		@icon = @player_shield_icon
  		@shield_sound_instance = @shield_sound.play
  	end
  end 
  
  def increase_shield
	@shield_count = @shield_count + 1
  end
  
  def deactivate_shield
    @shield = false
    @icon = @player_icon
    @shield_sound_instance.stop if @shield_sound_instance
  end
  
  def shield?
  	@shield
  end
  
  def shield_time_left
    return @shield_time_left unless @game_window.running
  	now = Time.now
  	@shield_time_left = (SHIELD_LENGTH - (now - @shield_time)).round
  end

  def hit_by?(balls)
    return false if shield?
    hit = balls.any? do |ball|
      Gosu::distance(@x+@icon.width/2, @y+@icon.height/2,ball.x + ball.icon.width/2, ball.y + ball.icon.height/2) < (@icon.height/2 + ball.icon.height/2 - HIT_BUFFER)
    end
    
    close = !hit && balls.any? do |ball|
      Gosu::distance(@x+@icon.width/2, @y+@icon.height/2,ball.x + ball.icon.width/2, ball.y + ball.icon.height/2) < (@icon.height/2 + ball.icon.height/2 - CLOSE_BUFFER)
    end
    if close 
          @close_sound_instance = @close_sound.play unless @close_sound_instance
    else
    	@close_sound_instance.stop if @close_sound_instance
    	@close_sound_instance = nil
    end
    
    hit  
  end


end

class Ball
  attr_accessor :icon
  def initialize(game_window, player, xinc = 0, yinc = 10, xinit = lambda {rand(@game_window.width)}, yinit = lambda {0})
    @game_window = game_window
    @icon = Gosu::Image.new(@game_window, "default/asteroid.png", true)
    @player = player
    @xinc = xinc
    @yinc = yinc
    @xinit = xinit
    @yinit = yinit
    reset!
  end

  def update
    if (@y > @game_window.height || @x > @game_window.width)
      @player.increase_score
      reset!
    else
      @y = @y + @yinc
      @x = @x + @xinc
    end
  end

  def draw
    @icon.draw(@x,@y,2)
  end

  def x
    @x
  end
 
  def y
    @y
  end

  def reset!
    @y = @yinit.call
    @x = @xinit.call
  end
end

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

window = MyGame.new
window.show