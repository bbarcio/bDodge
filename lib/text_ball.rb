class TextBall < Ball
  TOP_ROW = %w(w e r t y u i o p)
  HOME_ROW = %w(a s d f g h j k l ;)
  BOTTOM_ROW = %w(z x c v b n m , . /)
  attr_accessor :letters

  def initialize(game_window, player, xinc = 0, yinc = 10, xinit = lambda {rand(@game_window.width)}, yinit = lambda {0})
    @font = Gosu::Font.new(game_window, Gosu::default_font_name, 70)
    @letters = HOME_ROW
    super
  end

  def draw
    super
    @font.draw(@letter, @x + (@icon.width/2-@font.text_width(@letter)/2), @y,3,1,1,0xffffffff)
  end

  def update
    if @letter == @player.last_keypress
      @player.last_keypress = ''
      @player.increase_score
      reset!
    end
    if (@y > @game_window.height || @x > @game_window.width || @y < 0 || @x < 0)
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

  def set_config(config)
    config.each {|k,v| self.send("#{k}=",TextBall.const_get(v))}
  end
  def reset!
    @letter = get_letter
    super
  end

  def get_letter
    letters[rand(letters.size)]
  end
end

