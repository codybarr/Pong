--[[
	GD50 2018
	Pong Remake

	-- Main Program --

	Author: Cody Barr

	Originally programmed by Atari in 1972. Features two
	paddles, controlled by players, with the goal of getting
	the ball past your opponent's edge. First to 10 points wins.

	Most of the code here comes from CS50's Intro to Game development
	course which you can audit for free here: https://www.edx.org/course/cs50s-introduction-to-game-development

	Source Repo: https://github.com/games50/pong
]]

local push = require 'libs.push.push'
require 'Paddle'
require 'Ball'

GAME_WIDTH, GAME_HEIGHT = 432, 243 --fixed game resolution
WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

PADDLE_SPEED = 200
PADDLE_AI_SPEED = 70

PADDLE_HEIGHT = 50
HALF_PADDLE_HEIGHT = PADDLE_HEIGHT / 2
PADDLE_WIDTH = 5

BALL_SIZE = 10
HALF_BALL_SIZE = BALL_SIZE / 2
SPEED_MULTIPLIER = 1.15

function love.load()
	-- set love's default filter to "nearest-neighbor", which essentially
	-- means there will be no filtering of pixels (blurriness), which is
	-- important for a nice crisp, 2D look
	love.graphics.setDefaultFilter('nearest', 'nearest')
	
	love.window.setTitle('Pong')

	-- "seed" the RNG so that calls to random are always random
	-- use the current time, since that will vary on startup every time
	math.randomseed(os.time())

	-- initialize nice looking fonts
	smallFont = love.graphics.newFont('font.ttf', 8)
	largeFont = love.graphics.newFont('font.ttf', 16)
	scoreFont = love.graphics.newFont('font.ttf', 32)

	-- set LÖVE2D's active font to the smallFont object
	love.graphics.setFont(smallFont)

	-- set up our sound effects; later, we can just index this table and
	-- call each entry's `play` method
	sounds = {
		['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
		['score'] = love.audio.newSource('sounds/score.wav', 'static'),
		['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
	}


	-- initialize window with virtual resolution
	push:setupScreen(GAME_WIDTH, GAME_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = true,
		resizable = false,
		vsync = true
	})
	
	-- initialize score variables, used for rendering on the screen and keeping
	-- track of the winner
	player1Score = 0
	player2Score = 0
	
	servingPlayer = 1

	-- initialize our player paddles and ball
	player1 = Paddle(PADDLE_WIDTH, 30, PADDLE_WIDTH, PADDLE_HEIGHT)
	player2 = Paddle(GAME_WIDTH - (PADDLE_WIDTH * 2), GAME_HEIGHT - PADDLE_HEIGHT - 30, PADDLE_WIDTH, PADDLE_HEIGHT)
	ball = Ball(GAME_WIDTH / 2 - (BALL_SIZE / 2), GAME_HEIGHT / 2 - (BALL_SIZE / 2), BALL_SIZE)

	-- game state variable used to transition between different parts of the game
	-- (used for beginning, menus, main game, high score list, etc.)
	-- we will use this to determine behavior during render and update
	gameState = 'start'
end

function love.resize(w, h)
	push:resize(w, h)
end

--[[
	Runs every frame, with "dt" passed in, our delta in seconds 
	since the last frame, which LÖVE2D supplies us.
]]
function love.update(dt)
	if gameState == 'serve' then
		-- before switching to play, initialize ball's velocity based
		-- on player who last scored
		
	elseif gameState == 'play' then
		-- detect ball collision with paddles, reversing dx if true and
		-- slightly increasing it, then altering the dy based on the position of collision
		if ball:collides(player1) then
			ball.dx = -ball.dx * SPEED_MULTIPLIER
			ball.x = player1.x + PADDLE_WIDTH
			sounds['paddle_hit']:play()
		end
		
		if ball:collides(player2) then
			ball.dx = -ball.dx * 1.03
			ball.x = player2.x - BALL_SIZE
			sounds['paddle_hit']:play()
		end

		-- detect upper screen boundary and reverse ball delta-y
		if ball.y <= 0 then
			ball.y = 0
			ball.dy = -ball.dy
			sounds['wall_hit']:play()
		end

		-- detect lower screen boundary and reverse ball delta-y
		if ball.y + BALL_SIZE >= GAME_HEIGHT then
			ball.y = GAME_HEIGHT - BALL_SIZE
			ball.dy = -ball.dy
			sounds['wall_hit']:play()
		end
	end

	if ball.x + BALL_SIZE < 0 then
		player2Score = player2Score + 1
		servingPlayer = 1
		ball:reset()
		sounds['score']:play()

		if player2Score == 10 then
			winningPlayer = 2
			gameState = 'done'
		else
			gameState = 'serve'
		end
	end

	if ball.x > GAME_WIDTH then
		player1Score = player1Score + 1
		servingPlayer = 2
		ball:reset()
		sounds['score']:play()

		if player1Score == 10 then
			winningPlayer = 1
			gameState = 'done'
		else
			gameState = 'serve'
		end
	end
	
	-- player 1 movement (keyboard)
	if love.keyboard.isDown('w') then
		player1.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('s') then
		player1.dy = PADDLE_SPEED
	else
		player1.dy = 0
	end

	-- player 1 movement (touch)
	local touches = love.touch.getTouches()
 
	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		local gameX, gameY = push:toGame(x, y)

		-- if the touch is on the left third of the screen
		if gameX ~= nil and gameY ~= nil and gameX < GAME_WIDTH * .33 then
			if player1.y + HALF_PADDLE_HEIGHT < gameY then
				player1.dy = PADDLE_SPEED
			else
				player1.dy = -PADDLE_SPEED
			end
		end
	end

	-- player 2 AI
	if player2.y + HALF_PADDLE_HEIGHT < ball.y then
		player2.dy = PADDLE_AI_SPEED
	else
		player2.dy = -PADDLE_AI_SPEED
	end

	-- player 2 movement
	-- if love.keyboard.isDown('up') then
	-- 	player2.dy = -PADDLE_SPEED
	-- elseif love.keyboard.isDown('down') then
	-- 	player2.dy = PADDLE_SPEED
	-- else
	-- 	player2.dy = 0
	-- end

	-- Move Player 2 based on Mouse X Position
	-- x, y = push:toGame(0, love.mouse.getY())
	-- if y ~= nil then
	-- 	if y - HALF_PADDLE_HEIGHT <= 0 then
	-- 		player2.y = 0
	-- 	elseif y + HALF_PADDLE_HEIGHT >= GAME_HEIGHT then
	-- 		player2.y = GAME_HEIGHT - PADDLE_HEIGHT
	-- 	else
	-- 		player2.y = y - HALF_PADDLE_HEIGHT
	-- 	end
	-- end


	-- update our ball based on its DX and DY only if we're in play state;
	-- scale the velocity by dt so movement is framerate-independent
	if gameState == 'play' then
		ball:update(dt)
	end

	player1:update(dt)
	player2:update(dt)
end

--[[
	Keyboard handling, called by LÖVE2D each frame; 
	passes in the key we pressed so we can access.
]]
function love.keypressed(key)
	-- keys can be accessed by string name
	if key == 'escape' then
		-- function LÖVE gives us to terminate application
		love.event.quit()
	-- if we press enter during the start state of the game, we'll go into play mode
	-- during play mode, the ball will move in a random direction
	elseif key == 'enter' or key == 'return' then
		if gameState == 'start' then
			gameState = 'serve'
		elseif gameState == 'serve' then
			ball:serve(servingPlayer)
			gameState = 'play'
		elseif gameState == 'done' then
			gameState = 'serve'

			ball:reset()

			-- reset scores
			player1Score = 0
			player2Score = 0

			-- decide serving player (loser)
			if winningPlayer == 1 then
				servingPlayer = 2
			else
				servingPlayer = 1
			end
		end
	end
end

-- game state transitions for tapping the center of the screen
function love.touchreleased(id, x, y, dx, dy, pressure)
	relativeX, relativeY = push:toGame(x, y)

	-- print(string.format('Mouse clicked at: %d, %d', relativeX, relativeY))

	if relativeX ~= nil and relativeX > (GAME_WIDTH * .33) and relativeX < GAME_WIDTH * .66 then
		if gameState == 'start' then
			gameState = 'serve'
		elseif gameState == 'serve' then
			ball:serve(servingPlayer)
			gameState = 'play'
		elseif gameState == 'done' then
			gameState = 'serve'

			ball:reset()

			-- reset scores
			player1Score = 0
			player2Score = 0

			-- decide serving player (loser)
			if winningPlayer == 1 then
				servingPlayer = 2
			else
				servingPlayer = 1
			end
		end
	end
end

--[[
	Called after update by LÖVE2D, used to draw anything to the screen, 
	updated or otherwise.
]]
function love.draw()
	-- begin rendering at virtual resolution
	push:start()

	-- clear the screen with a specific color; in this case, a color similar
	-- to some versions of the original Pong
	love.graphics.clear(0, 0, 0, 255)

	-- draw different things based on the state of the game
	love.graphics.setFont(smallFont)
	displayScore()

	if gameState == 'start' then
		love.graphics.setFont(smallFont)
		love.graphics.printf('Welcome to Pong!', 0, 10, GAME_WIDTH, 'center')
		love.graphics.printf('Tap the middle of the screen to begin!', 0, 20, GAME_WIDTH, 'center')
	elseif gameState == 'serve' then
		love.graphics.setFont(smallFont)
		love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
			0, 10, GAME_WIDTH, 'center')
		love.graphics.printf('Tap the middle of the screen to serve!', 0, 20, GAME_WIDTH, 'center')
	elseif gameState == 'play' then
		-- no UI messages to display in play
	elseif gameState == 'done' then
		love.graphics.setFont(largeFont)
		love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, GAME_WIDTH, 'center')
		love.graphics.setFont(smallFont)
		love.graphics.printf('Tap the middle of the screen to restart', 0, 30, GAME_WIDTH, 'center')
	end
		
	-- render table boundaries
	love.graphics.rectangle('line', 0, 0, GAME_WIDTH, GAME_HEIGHT )

	player1:render()
	player2:render()

	ball:render()
	
	displayFPS()
	-- displayBallPos()

	push:finish()
end

function displayScore()
	-- draw score on the left and right center of the screen
	-- need to switch font to draw before actually printing
	love.graphics.setFont(scoreFont)
	love.graphics.print(tostring(player1Score), GAME_WIDTH / 2 - 50, 
		GAME_HEIGHT / 3)
	love.graphics.print(tostring(player2Score), GAME_WIDTH / 2 + 30,
		GAME_HEIGHT / 3)
end

function displayFPS()
	-- simple FPS display across all states
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.printf('Current FPS: ' .. tostring(love.timer.getFPS()), -10, 10, GAME_WIDTH, 'right')
end


function displayBallPos()
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0, 0, 255, 255)
	love.graphics.printf(string.format('Ball Position: %.1f,%.1f', ball.x, ball.y), -10, 30, GAME_WIDTH, 'right')
end