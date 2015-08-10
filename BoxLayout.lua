--
-- Author: wangbilt<wangbilt@gmail.com>
-- Date: 2015-05-12 14:30:09
--

local BoxLayout = class("BoxLayout", function()
	return cc.Node:create()
end)

function BoxLayout:ctor()
	self:setAnchorPoint(cc.p(0.5,0.5))
	self.item = {}
	
	if DEBUG_BOX_LAYOUT then
	    self.bg = display.newColorLayer(ccc4(100,100,100,255))
	        :addTo(self,-1)
    end
end

function BoxLayout:count()
	return #(self.item)
end

function BoxLayout:clear()
	self.item = {}
	self:removeAllChildren()
end

function BoxLayout:insert(_item, _index, _params)
	_params = _params or {}
	_params.l= _params.l or 0
	_params.r= _params.r or 0
	_params.t= _params.t or 0
	_params.b= _params.b or 0

	_item:setAnchorPoint(cc.p(0.5, 0.5))

	local item = {item=_item, params = _params}
	if _index then
		table.insert(self.item, _index, item)
	else
		table.insert(self.item, item)
	end
	self:addChild(_item)

	return _item
end

function BoxLayout:removeByTag(_tag, _all)
	while true do
		local isfind = false
		for i,v in ipairs(self.item) do
			if v.params.tag and v.params.tag == _tag then
				self:remove(i)
				isfind = true
				break
			end
		end
		if not isfind or not _all then
			break
		end
	end
end

function BoxLayout:remove(_id)
	if #(self.item) <= 0 then
		return
	end
	local layout = self.item[_id]
	table.remove(self.item, _id)
	self:removeChild(layout.item)	
end

function BoxLayout:push(_item, _params)
	return self:insert(_item, nil, _params)
end

function BoxLayout:pushGrid(_item_list, _stripe, _direction, _params, _padding)
	_params = _params or {}
	
	if _direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL then
		_params.align = _params.align or display.LEFT_CENTER
	elseif _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL and not _params.h then
		_params.align = _params.align or display.CENTER_TOP
	end
	
	local box = nil
	local len = #(_item_list)
	local size = nil
	for i,v in ipairs(_item_list) do
		if not box then
			box = BoxLayout.new()
		end
		box:push(v, _padding)
		if i%_stripe == 0 or i == len then
			if _direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL and not _params.w then
				_params.w = math.max(_params.w or 0, box:measure(_direction, _params.padding or 0).w)
			elseif _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL and not _params.h then
				_params.h = math.max(_params.h or 0, box:measure(_direction, _params.padding or 0).h)
			end
			box:layout(_direction, _params)
			self:push(box)
			box = nil
		end
	end
end

function BoxLayout:pop()
	return self:remove(#(self.item))
end

function BoxLayout:getItem(_id)
	return assert(self.item[_id])
end

function BoxLayout:getItemSize(_item)
	local box = _item:getBoundingBox()
	return cc.size(box.width, box.height)
end

function BoxLayout:measure(_direction, _padding)
	local w,h = 0,0
	local size = nil
	for i,v in ipairs(self.item) do
		size = self:getItemSize(v.item)
		if _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL then
			w = math.max(w, size.width+v.params.l+v.params.r) 
			h = h + size.height+v.params.t+v.params.b
		elseif _direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL then
			h = math.max(h, size.height+v.params.t+v.params.b) 
			w = w + size.width+v.params.l+v.params.r
		end
	end
	if _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		h = h + (#(self.item) - 1) * _padding
	elseif _direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL then
		w = w + (#(self.item) - 1) * _padding
	end

	return {w=w,h=h}
end

function BoxLayout:layout(_direction, _params)
	_params = _params or {}
	_params.padding = _params.padding or 0
	_params.align   = _params.align or display.CENTER
	
	local src_size = self:measure(_direction, _params.padding)

	if _params.w then
		_params.w = math.max(_params.w, src_size.w)
	else
		_params.w = src_size.w
	end

	if _params.h then
		_params.h = math.max(_params.h, src_size.h)
	else
		_params.h = src_size.h
	end

	self:setContentSize(cc.size(_params.w, _params.h))
	
	if DEBUG_BOX_LAYOUT then
	    self.bg:setContentSize(cc.size(_params.w, _params.h))
    end

    if _direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL then
    	self:hlayout(_params, src_size.w, display.ANCHOR_POINTS[_params.align])
	elseif _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL then
    	self:vlayout(_params, src_size.h, display.ANCHOR_POINTS[_params.align])
    end
end

function BoxLayout:hlayout(_params, _w, _anchor)
	local x = _anchor.x*(_params.w - _w)
	local y = 0
	local size = nil
	for i,v in ipairs(self.item) do
		size = self:getItemSize(v.item)
		y = _anchor.y * _params.h + (1 - v.item:getAnchorPoint().y - _anchor.y) * size.height
		x = x + v.params.l + size.width/2
		v.item:setPosition(x,y)
		x = x + size.width/2 + v.params.r + _params.padding
	end
end

function BoxLayout:vlayout(_params, _h, _anchor)
	local x = 0
	local y = _h - (_anchor.y * (_params.h - _h))
	local size = nil
	for i,v in ipairs(self.item) do
		size = self:getItemSize(v.item)
		x = _anchor.x * _params.w + (1 - v.item:getAnchorPoint().x - _anchor.x) * size.width
		y = y - (v.params.t + size.height/2)
		v.item:setPosition(x,y)
		y = y - (size.height/2 + v.params.b + _params.padding)
	end
end

return BoxLayout