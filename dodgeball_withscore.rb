require 'rubygems'
require 'gosu'
require 'yaml'
#pond5.com to purchase? media royalty free
class MyGame < Gosu::Window
  attr_reader :running
  PADDING = 10
  def initialize
    super(800, 800, false)
    @player1 = Player.new(self)
    @level = Level.new(self, @player1)
    @running = true
    self.caption = "Dodgeball in space"
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @highscore = 0
  end

  def update
    if @running

      @player1.update
      @level.update
      if @player1.hit_by? @level.balls
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
    @player1.draw
    @level.draw
    score_text = "Score: #{@player1.score}"
    @font.draw(score_text, width - (@font.text_width(score_text)+PADDING),PADDING,3)
    highscore_text = "Highscore: #{@highscore}"
    @font.draw(highscore_text, width/2 - (@font.text_width(highscore_text)/2),PADDING,3)
    level_text = "Level #{@level.level + 1} (#{@level.time_left})"
    @font.draw(level_text, PADDING,PADDING,3)
    if @player1.shield?
    	shield_text = "Shield Remaining #{@player1.shield_time_left}"
    	@font.draw(shield_text, PADDING, height - (20 + PADDING),3)
	else
		shield_text = "Shield: #{@player1.shield_count}"
    	@font.draw(shield_text, PADDING, height - (20 + PADDING),3)
	end
    unless @running
      restart_text = "Hit 'esc' to restart"
      @font.draw(restart_text, width/2 - (@font.text_width(restart_text)/2),height/2 - (20)/2,3)
    end
    
  end

  def stop_game!
    @running = false
    @highscore = @player1.score if @player1.score > @highscore
  end

  def restart_game
    @running = true
    @level.reset
    @player1.reset
  end
end

class Player
  SHIELD_LENGTH = 3
  attr_reader :shield_count
  def initialize(game_window)
    @game_window = game_window
    @icon = Gosu::Image.new(@game_window, "player1.png", true)
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
    @score = @score + 1
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
    if @x > (@game_window.width - 100)
      @x = @game_window.width - 100
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
  		@icon = Gosu::Image.new(@game_window, "player1_neon.jpg", true)
  	end
  end 
  
  def increase_shield
	@shield_count = @shield_count + 1
  end
  
  def deactivate_shield
  	if @shield
  		@shield = false
  		@icon = Gosu::Image.new(@game_window, "player1.png", true)
    end
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
    balls.any? {|ball|Gosu::distance(@x, @y, ball.x, ball.y) < 50}
  end


end

class Ball
  def initialize(game_window, player, xinc = 0, yinc = 10, xinit = lambda {rand(@game_window.width)}, yinit = lambda {0})
    @game_window = game_window
    @icon = Gosu::Image.new(@game_window, "asteroid.png", true)
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
		@level = @level + 1
		start_level
	end
  end
  
  def draw
    @balls.each {|ball| ball.draw}
  end
  
  def start_level    
    if @level >= @@level_config.size
    	@current_config = @@level_config[@@level_config.size - 1]
    else
    	@current_config = @@level_config[@level]
    end
    @balls = []

  	@balls = @balls + @current_config[:from_top].times.map {Ball.new(@game_window, @player, 0, 10, lambda {rand(@game_window.width)}, lambda {0})} if @current_config[:from_top]
  	@balls = @balls + @current_config[:from_left].times.map {Ball.new(@game_window, @player, 10, 0, lambda {0}, lambda {rand(@game_window.width)})} if @current_config[:from_left]
    @start_time = Time.now
    @player.increase_shield
  end
  
  def reset
    @start_time = Time.now
  	@level = 0
  	start_level
  end
end

window = MyGame.new
window.show