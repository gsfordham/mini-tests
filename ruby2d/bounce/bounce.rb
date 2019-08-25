#! /usr/bin/ruby
#bounce.rb

require 'ruby2d'

#Constants
NAME = 'Freefall Bouncer'

INIT_X = (Window.width / 2).floor
INIT_Y = 25
INIT_XSPEED = 100

ACCEL = 9.81 * 25
W_FRICTION = 0.5 #Wall/floor friction
ELASTICITY = 0.3 #How much friction is ignored

GOOD = 'green'
BAD = 'red'
MAYBE = 'yellow'

#Controllers
tdif = 0
start_tick = 0

#Avatar to move
@avatar = Circle.new x: INIT_X, y: INIT_Y, radius: 13, color: MAYBE

#Error correction
hlist = []
wlist = []

#Speeds of avatar
@xspeed = 0
@freefall = 0

#Whether the simulation is running
@running = false

set title: NAME

#Get the distance with speed, time, accel
#s = v₁t + ½at² -- v₁ = initial velocity
def distance vel, accel, time
	((vel * time) + (0.5 * accel * (time**2)))
end

#Get final velocity
def vfin vel, accel, time
	#puts "VFIN V: #{vel}; A: #{accel}; T: #{time}"
	(vel + (accel * time))
end

#Key handling
on :key_down do |event|
	case event.key
	when 'a' #Throw LEFT
		@running = true #Sim is running
		@xspeed += -INIT_XSPEED #Launch avatar to left
		wlist = [] #Reset the list to avoid error
		start_tick = Time.new
	when 'd' #Throw RIGHT
		@running = true #Sim is running
		@xspeed += INIT_XSPEED #Launch avatar to right
		wlist = [] #Reset the list to avoid error
		start_tick = Time.new
	when 's' #Drop STRAIGHT
		@running = true #Sim is running
		start_tick = Time.new
	when 'r' #Reset
		@running = false #System is NOT running
		@avatar.color = MAYBE #Initial color is yellow
		start_tick = 0
		
		#Reset speeds
		@xspeed = 0
		@freefall = 0
		
		#Reset lists
		hlist = []
		wlist = []
		
		#Reset x and y coords
		@avatar.x = INIT_X
		@avatar.y = INIT_Y
	when 'q' #Quit
		close
	end
end

update do
	#Init crashes and bounces
	crash = 0
	
	#Decide whether to increment ticker
	if @running
		#Difference in time
		tdif = Time.new - start_tick
		vi = @freefall
		
		#Get changes in Y
		newy = distance @freefall, ACCEL, tdif.to_f
		
		#Get changes in X
		newx = distance @xspeed, 0, tdif.to_f
		
		#If the distance exceeds the screen, it has hit the floor
		if @avatar.y + newy >= Window.height
			@freefall = -(@freefall - (@freefall * (W_FRICTION - ELASTICITY)))
			crash += 1
			newy = distance @freefall, ACCEL, tdif.to_f
		end
		@avatar.y += newy.round(0)
		
		#If the ball hits the side of the screen
		xfix = @avatar.x + newx
		if xfix >= Window.width || xfix <= 0
			crash += 1
			@xspeed = -@xspeed
		end
		
		#Add another slowing effect to X on bounce
		if crash > 0
			crash.downto(1) do
				@xspeed = (@xspeed - (@xspeed * (W_FRICTION - ELASTICITY)))
			end
			newx = distance @xspeed, 0, tdif.to_f
		end
		@avatar.x += newx.round(0)
		
		start_tick = Time.new
		vf = (vfin @freefall, ACCEL, tdif.to_f)
		
		#Kill the Y speed if it's basically 0
		hlist << @avatar.y
		if hlist.length > 10
			hlist = hlist[1,10]
			
			avg = hlist.inject(0, :+) / hlist.length
			if avg.round(1) == hlist.min.round(1) && avg.round(1) == hlist.max.round(1) && @avatar.y.floor == Window.height
				vf = 0
				@avatar.y = Window.height
			end
		end
		@freefall = vf.round(3)
		
		#Kill the X speed if it's basically 0
		wlist << @avatar.x
		if wlist.length > 10
			wlist = wlist[1,10]
			
			avg = wlist.inject(0, :+) / wlist.length
			if avg.between?(wlist.min, wlist.max) && wlist.min.round(1) == wlist.max.round(1)
				@xspeed = 0
				@avatar.x = @avatar.x.round(3)
			end
		end
		@xspeed = @xspeed.round(3)
		
		#Change color of avatar on impact
		if crash > 0
			@avatar.color = BAD
		else
			@avatar.color = GOOD
		end
		
		#Kill simulation on 0 speed
		if @xspeed == 0 && @freefall == 0
			@running = false
			puts "---------\nSimulation end\n---------\n\n"
		end
	end
end

show
