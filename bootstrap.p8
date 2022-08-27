pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--physics bootstrap
--by spratt

actors={}

-- static only
walls={}
-- balls, enemies, etc. anything that will be mostly controlled by physics
objects={}

showlogs=true

function _init()
	_wall(0,0,127,0)
	_wall(0,0,0,84)
	_wall(127,0,127,84)
	_wall(0,84,20,127)
	_wall(127,84,107,127)
	_wall(20,127,107,127)
	for i=1,20 do
		ball=_circ(rnd(128),rnd(64)+10,rnd(10)+2,false)
	end 
end

function _update()
	--apply forces etc
	local sim=4
	for i=1,sim do
		for o in all(objects) do
			o:update(1/sim)
		end
	end
end

function _draw()
	cls()
	for w in all(walls) do
		w:draw()
	end
	for a in all(actors) do
		a:draw()
	end
	print((flr(stat(1)*1000)/10).."%",11)
	-- print(sqrt(ball.dx*ball.dx+ball.dy*ball.dy))
	--logging
	if showlogs then
		for l in all(logs) do
			print(l[2],l[3])
			l[1]-=1
			if (l[1]<=0) then
				del(logs,l)
			end
		end
	end
end
-->8
--actors

function _actor(_x,_y)
	local a={
		x=_x,
		y=_y
	}

	function a.draw(me)
		--basic draw function
		circ(me.x,me.y,1,8)
	end
	
	function a.update(me)
		--basic update function
	end

	add(actors,a)

	return a
end
-->8
--objects

function _circ(_x,_y,_r,_s)
	local c = _actor(_x,_y)
	c.r=_r
	c.static =_s or false
	c.dx=0
	c.dy=0
	c.m=1
	c.clr=_s and 13 or 8

	function c.draw(me)
		--basic draw function
		circ(me.x,me.y,me.r,me.clr)
	end
	
	function c.update(me,ts)
		--basic update function

		--should maybe do all the gravity at once..?
		me.dy+=0.1*ts
		me.x+=me.dx*ts
		me.y+=me.dy*ts

		local staticcols = {}
		local dynamiccols = {}
		for i=1,5 do
			--collide with walls
			local dx,dy
			--deepest collision
			local dpst={0}
			for w in all(walls) do
				--get closest point on wall
				local tx,ty=w.x2-w.x1,w.y2-w.y1
				if ((me.x-w.x1)*tx+(me.y-w.y1)*ty<=0) then
					dx,dy=me.x-w.x1,me.y-w.y1
				elseif ((me.x-w.x2)*tx+(me.y-w.y2)*ty>=0) then
					dx,dy=me.x-w.x2,me.y-w.y2
				else
					tx/=w.len
					ty/=w.len
					local k=tx*(me.x-w.x1)+ty*(me.y-w.y1)
					dx,dy=me.x-w.x1-tx*k,me.y-w.y1-ty*k
				end

				if (dx*dx+dy*dy<me.r*me.r) then
					--collision!
					local d=sqrt(dx*dx+dy*dy)
					if (dpst[1]<me.r-d) then
						dpst={me.r-d,dx/d,dy/d,w}
					end
				end
			end
			--collide with other objects
			for o in all(objects) do
				if (o != me) then
					dx,dy=me.x-o.x,me.y-o.y
					r=me.r+o.r
					if (dx*dx+dy*dy<r*r) then
						--collision!
						local d=sqrt(dx*dx+dy*dy)
						if (dpst[1]<r-d) then
							dpst={r-d,dx/d,dy/d,o}
						end
					end
				end
			end

			--if collision depth = 0, then break
			if (dpst[1]==0) then
				break
			else
				me.x+=dpst[1]*dpst[2]
				me.y+=dpst[1]*dpst[3]
				
				--put collision info into buffer, removing duplicates if any
				if (dpst[4].static) then
					for n in all(staticcols) do
						if (dpst[4] == n[4]) then
							del(staticcols,n)
						end
					end
					add(staticcols,dpst)
				else
					for n in all(dynamiccols) do
						if (dpst[4] == n[4]) then
							del(dynamiccols,n)
						end
					end
					add(dynamiccols,dpst)
				end

				dpst[4]:oncollide(me)
			end
		end
		--static collisions
		if #staticcols>0 then
			--average all collision normals
			local rx,ry=0,0
			for n in all(staticcols) do
				if n[4].static then 
					rx+=n[2]
					ry+=n[3]
				end
			end
			local d=sqrt(rx*rx+ry*ry)
			rx/=d
			ry/=d
			local k=2*(me.dx*rx+me.dy*ry)
			me.dx-=k*rx
			me.dy-=k*ry
		end
		--dynamic collisions
		if #dynamiccols>0 then
			for n in all(dynamiccols) do
				local o=n[4]			
				local d2=(me.r+o.r)*(me.r+o.r)
				local k=2*((me.dx-o.dx)*(me.x-o.x)+(me.dy-o.dy)*(me.y-o.y))/(me.m+o.m)/d2

				me.dx-=k*o.m*(me.x-o.x)
				me.dy-=k*o.m*(me.y-o.y)

				o.dx-=k*me.m*(o.x-me.x)
				o.dy-=k*me.m*(o.y-me.y)
			end
		end
	end

	function c.oncollide(me,you)
		--called when something collides with it
	end
	
	add(objects,c)
	return c
end
-->8
--walls

function _wall(_x1,_y1,_x2,_y2)
	local w={
		x1=_x1,
		y1=_y1,
		x2=_x2,
		y2=_y2,
		static=true, --walls are always static
		r=1,
		len=sqrt((_x2-_x1)*(_x2-_x1) + (_y2-_y1)*(_y2-_y1))
	}

	function w.draw(me)
		--basic draw function
		line(me.x1,me.y1,me.x2,me.y2,15)
	end
	
	function w.update(me)
		--basic update function
	end

	function w.oncollide(me,you)
		--called when something collides with it
	end
	
	add(walls,w)
	
 return w
end
-->8
--utils

--logging
logs={}
lcol=true
function log(txt)
	if (#logs>=20) then
		del(logs,logs[1])
	end
	lcol=not lcol
	add(logs,{120,txt,lcol and 6 or 7})
end

--basic insertion sort with comparator function input
function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
    j = j - 1
    end
  end
end

__gfx__
0000000000666d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700677766d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000667666d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700d6666d550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005ddd5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
