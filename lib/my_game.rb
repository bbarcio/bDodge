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
    @running = false
    @paused = false
    self.caption = "bDodge"
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @highscores = YAML::load(File.open 'highscores.yml')
    @background_color = BLACK
    @font_color = WHITE
    @death_sound = Gosu::Sample.new(self, "default/death.mp3")
    @music = Gosu::Song.new(self, "default/bSong1.mp3")
  	@music.play(true)
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
  
  def button_down(id)
  	if id == Gosu::Button::KbM
		if @music.playing?
			@music.stop 
		else
			@music.play(true) unless @music.playing?
		end
  	end
  	if id == Gosu::Button::KbQ
      	self.close
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
