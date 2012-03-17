require 'rubygems'
require 'gosu'

#pond5.com to purchase? media royalty free
class MyGame < Gosu::Window
  PADDING = 10
  def initialize
    super(800, 800, false)
    @player1 = Player.new(self)
    @level = Level.new(self, @player1)
    @running = true
    self.caption = "Dodgeball in space"
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
  end

  def update
    if @running
   
      if button_down? Gosu::Button::KbLeft
        @player1.move_left
      end

      if button_down? Gosu::Button::KbRight
        @player1.move_right
      end

      if button_down? Gosu::Button::KbUp
        @player1.move_up
      end

      if button_down? Gosu::Button::KbDown
        @player1.move_down
      end
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
    @font.draw(score_text, width - (@font.text_width (score_text)+PADDING),PADDING,3)
    unless @running
      @font.draw("Hit 'esc' to restart", PADDING,PADDING,3)
    end
    
  end

  def stop_game!
    @running = false
  end

  def restart_game
    @running = true
    @level.reset
    @player1.reset_score
  end
end

class Player
  def initialize(game_window)
    @game_window = game_window
    @icon = Gosu::Image.new(@game_window, "player1.png", true)
    @x = 250
    @y = 700
    @score = 0
  end

  def score
    @score
  end

  def reset_score
    @score = 0
  end
  
  def increase_score
    @score = @score + 1
  end
  
  def draw
    @icon.draw(@x,@y,1)
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
    if @y > (@game_window.height - 75)
      @y = @game_window.height - 75
    else
      @y = @y + 10
    end
  end

  def hit_by?(balls)
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
  
  def initialize(game_window, player)
    @game_window = game_window
    @player = player
    @balls = 3.times.map {Ball.new(game_window, player)}
    reset
  end 
  
  def update
      @balls.each {|ball| ball.update}
  end
  
  def draw
    @balls.each {|ball| ball.draw}
  end

  def reset
  	@balls.each {|ball| ball.reset!}
  	@level = 0
  end
end

window = MyGame.new
window.show