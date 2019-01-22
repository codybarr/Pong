--[[
	GD50 2018
	Pong Remake

	-- Ball Class --

	Author: Colton Ogden
	cogden@cs50.harvard.edu

	Represents a ball which will bounce back and forth between paddles
	and walls until it passes a left or right boundary of the screen,
	scoring a point for the opponent.
]]

local Class = require('libs.hump.class')
Ball = Class{}

local BALL_SPEED = 100 -- 1000

function Ball:init(x, y, size)
	self.x = x
	self.y = y
	self.size = size

	-- these variables are for keeping track of our velocity on both the
	-- X and Y axis, since the ball can move in two dimensions
	self.dy = math.random(2) == 1 and -BALL_SPEED or BALL_SPEED
	self.dx = math.random(2) == 1 and -BALL_SPEED or BALL_SPEED
end

--[[
	Expects a paddle as an argument and returns true or false, depending
	on whether their rectangles overlap.
]]
function Ball:collides(paddle)
	-- first, check to see if the left edge of either is farther to the right
	-- than the right edge of the other
	if self.x > paddle.x + paddle.width or paddle.x > self.x + self.size then
		return false
	end

	-- then check to see if the bottom edge of either is higher than the top
	-- edge of the other
	if self.y > paddle.y + paddle.height or paddle.y > self.y + self.size then
		return false
	end 

	-- if the above aren't true, they're overlapping
	return true
end

--[[
	Places the ball in the middle of the screen, with an initial random velocity
	on both axes.
]]

function Ball:serve(servingPlayer)
	ball.dy = math.random(2) == 1 and -BALL_SPEED or BALL_SPEED
	if servingPlayer == 1 then
		ball.dx = BALL_SPEED
	else
		ball.dx = -BALL_SPEED
	end
end

function Ball:reset()
	self.x = GAME_WIDTH / 2 - (self.size / 2)
	self.y = GAME_HEIGHT / 2 - (self.size / 2)
	self.dy = math.random(2) == 1 and -BALL_SPEED or BALL_SPEED
	self.dx = math.random(2) == 1 and -BALL_SPEED or BALL_SPEED
end

--[[
	Simply applies velocity to position, scaled by deltaTime.
]]
function Ball:update(dt)
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt
end

function Ball:render()
	love.graphics.rectangle('fill', self.x, self.y, self.size, self.size)
end