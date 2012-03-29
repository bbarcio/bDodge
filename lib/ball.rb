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
    if (@y > @game_window.height || @x > @game_window.width || @y < 0 || @x < 0)
      @player.increase_score
      reset!
    else
      if @yinc.respond_to? :call
         @y = @yinc.call(@x, @y, @xstart, @ystart)
      else
         @y = @y + @yinc
      end
      if @xinc.respond_to? :call
         @x = @xinc.call(@x, @y, @xstart, @ystart)
      else      
        @x = @x + @xinc
      end
    end
  end

  def draw
    @icon.draw(@x,@y,MyGame::Z_BALL)
  end

  def x
    @x
  end
 
  def y
    @y
  end

  def reset!
    @y = @ystart = @yinit.call
    @x = @xstart = @xinit.call
  end
end

