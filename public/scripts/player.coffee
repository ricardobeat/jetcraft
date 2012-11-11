class Player
	constructor:->
		@id
		@X
		@Y
		@speed_x
		@speed_y
		@default_speed = 10
		@default_gravity = 10
		@jump_limit = 10
		@jumping = false
		@falling = false
		@moving_left = false
		@moving_right = false


	update:->
		@X += @speed_x | 0
		@Y += @speed_y | 0

	moveRight:->
		@speed_x += @default_speed if @speed_x < @default_speed

	moveLeft:->
		@speed_x -= @default_speed if @speed_x < @default_speed

	jump:->
		if(!@falling && @speed_y > -@jump_limit)
			@speed_y -= @jump_limit / 2

