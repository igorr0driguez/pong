--VSCODE DEBUGGER INITIALIZATION
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end
function love.conf(t)
	t.console = false
end

--LIBRARIES
push = require 'push'
Class = require 'class'

require 'Paddle'
require 'Ball'

--CONSTANTS
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

--GAME START
function love.load()
	love.graphics.setDefaultFilter('nearest', 'nearest')

	love.window.setTitle('PONG')

	math.randomseed(os.time())

	smallFont = love.graphics.newFont('font.ttf', 8)
	mediumFont = love.graphics.newFont('font.ttf', 32)

	love.graphics.setFont(smallFont)

	--sounds
	sounds = {
		['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
		['score'] = love.audio.newSource('sounds/score.wav', 'static'),
		['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
	}

	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		resizable = true,
		vsync = true
	})

	--initializing ball and players
	ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
	player1 = Paddle(10, 30, 5, 20)
	player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 20)
	player1Score = 0
	player2Score = 0
	servingPlayer = math.random(2) == 1 and 1 or 2

	gameState = 'start'
end

--UPDATES LOGIC EVERY FRAME
function love.update(dt)
	--serving logic
	if gameState == 'serve' then
		ball.dy = math.random(-100, 100)
		if servingPlayer == 1 then
			ball.dx = math.random(100, 200)
		elseif servingPlayer == 2 then
			ball.dx = math.random(-200, -100)
		end
	elseif gameState == 'play' then
		-- ball collision
		if ball:collides(player1) then
			sounds['paddle_hit']:play()
			ball.dx = -ball.dx * 1.03
			ball.x = player1.x + 5

			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end
		end
		if ball:collides(player2) then
			sounds['paddle_hit']:play()
			ball.dx = -ball.dx * 1.03
			ball.x = player2.x - 4

			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end
		end

		--fix ball leaving game window boundaries
		if ball.y <= 0 then
			sounds['wall_hit']:play()
			ball.y = 0
			ball.dy = -ball.dy
		end

		if ball.y >= VIRTUAL_HEIGHT - 4 then
			sounds['wall_hit']:play()
			ball.y = VIRTUAL_HEIGHT - 4
			ball.dy = -ball.dy
		end

		if ball.x < 0 then
			pointHandler(1)
		elseif ball.x > VIRTUAL_WIDTH then
			pointHandler(2)
		end
		ball:update(dt)
	end

	--player 1 movement
	if love.keyboard.isDown('w') then
		player1.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('s') then
		player1.dy = PADDLE_SPEED
	else 
		player1.dy = 0
	end

	--player 2 movement
	if love.keyboard.isDown('up') then
		player2.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('down') then
		player2.dy = PADDLE_SPEED
	else
		player2.dy = 0
	end

	player1:update(dt)
	player2:update(dt)
end

--UPDATES GRAPHICS EVERY FRAME AFTER UPDATE
function love.draw()
	push:apply('start')

	love.graphics.clear(40/255, 45/255, 52/255, 255/255)

	displayScore()
	--set small font for the title
	love.graphics.setFont(smallFont)
	if gameState == 'start' then
		love.graphics.printf('WELCOME TO PONG!\nPRESS ENTER TO PLAY', 0, 20, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'serve' then
		love.graphics.printf('PLAYER ' .. tostring(servingPlayer) .. " SERVES!\nPRESS ENTER TO SERVE!",
		0, 20, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'matchEnd' then
		local winner = player1Score > player2Score and '1' or '2';
		love.graphics.printf('PLAYER ' .. tostring(winner) .. " WON!\nPRESS ENTER PLAY AGAIN!",
		0, 20, VIRTUAL_WIDTH, 'center')
	else
		--no UI messages to display on play mode
	end

	--left paddle
	player1:render()
	--right paddle
	player2:render()
	--ball
	ball:render()

	--show fps top left of the screen
	love.graphics.printf(tostring(love.timer.getFPS()), 0, 0, VIRTUAL_WIDTH, 'left')
	push:apply('end')
end

--ACCESS PRESSED KEYS
function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	elseif key == 'enter' or key == 'return' then
		if gameState == 'start' then
			gameState = 'serve'
		elseif gameState == 'serve' then
			gameState = 'play'
		elseif gameState == 'matchEnd' then
			player1Score = 0
			player2Score = 0
			gameState = 'start'
		end
	end
end

function displayScore()
	love.graphics.setFont(mediumFont)
	love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 66, VIRTUAL_HEIGHT / 3 - 40)
	love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 50, VIRTUAL_HEIGHT / 3 - 40)
end

--handle what happens after a point is scored
function pointHandler(server)
	sounds['score']:play()
	servingPlayer = server
	if server == 1 then
		player2Score = player2Score + 1
	else
		player1Score = player1Score + 1
	end
	ball:reset()
	if player1Score >= 10 or player2Score >= 10 then
		gameState = 'matchEnd'
	else
		gameState = 'serve'
	end
end

function love.resize(w, h)
	push:resize(w, h)
end