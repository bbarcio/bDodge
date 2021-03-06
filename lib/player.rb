class Player
  HIT_BUFFER = 30
  CLOSE_BUFFER = -60
  SHIELD_LENGTH = 3
  NUM_LIVES = 3
  attr_accessor :lives
  attr_reader :shield_count
  attr_accessor :player_icon, :player_shield_icon
  attr_accessor :last_keypress
  def initialize(game_window)
    @game_window = game_window
    @player_icon = Gosu::Image.new(@game_window, "default/player1.png", true)
    @player_shield_icon = Gosu::Image.new(@game_window, "default/player1_neon.png", true)
    @icon = @player_icon
    @close_sound = Gosu::Sample.new(@game_window, "default/close_shave.mp3")	
    @shield_sound = Gosu::Sample.new(@game_window, "default/shield.mp3")	
	reset
  end

  def score
    @score
  end

  def reset
    return if @icon.nil?
    @x = @game_window.width/2 - @icon.width/2
    @y = @game_window.height - @icon.height
    @score = 0
    @shield = false
    @shield_count = 0
    @shield_time_left = 0
    @lives = NUM_LIVES
  end
  
  def increase_score
    @score = @score + 10
  end
  
  def draw
    return if @icon.nil?
    @icon.draw(@x,@y,MyGame::Z_PLAYER) unless @icon.nil?
  end

  def update
      return if @icon.nil?
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

	if (@shield_time_left < 0 )
	  deactivate_shield
	end
    @shield_time_left -= 1 if @shield
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
  		@shield_time_left = SHIELD_LENGTH * MyGame::FRAME_RATE
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
    return (@shield_time_left.to_f/(MyGame::FRAME_RATE)).round 
  end

  def hit_by?(balls)
    return false if @icon.nil?
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
    if hit
      @lives = @lives - 1 
      balls.each {|ball| ball.reset!}
    end
    hit  
  end
end