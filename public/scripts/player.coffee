class Player
	constructor:->
		@id
		@X
		@Y
		@speed_x
		@speed_y
		@default_speed = 10
		@gravity
		@default_gravity = 10
		@gravity_limit = 30
		@jump_limit = 10
		@jumping = false
		@falling = false
		@moving_left = false
		@moving_right = false
		@has_floor = true


	update:->
		@X += @speed_x | 0
		@Y += @speed_y | 0

		if not @has_floor
			@falling = true
			@gravity = @default_gravity
		else
			@falling = false
			@gravity = 0 #shut down gravity if we do, for processor's sake!

		if @falling
			@speed_y += @gravity if @gravity < @gravity_limit else @gravity_limit


	moveRight:->
		@speed_x += @default_speed if @speed_x < @default_speed else @default_speed

	moveLeft:->
		@speed_x -= @default_speed if @speed_x < @default_speed else @default_speed

	jump:->
		@gravity = @default_gravity
		if(!@falling && @speed_y > -@jump_limit)
			@speed_y -= @jump_limit / 2
		else
			@falling = true


