--
-- Author: wangbilt<wangbilt@gmail.com>
-- Date: 2015-05-12 14:30:09
--

local BoxLayout = class("BoxLayout", function()
	return cc.Node:create()
end)

BoxLayout.debug = false

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

function BoxLayout:preload(_count, _params)
	assert(_params and _params.size)
	for i=1, _count do
		self:insert(nil, nil, clone(_params))
	end
end

function BoxLayout:insert(_node, _index, _params)
	_params        = _params        or {}
	_params.l      = _params.l      or 0
	_params.r      = _params.r      or 0
	_params.t      = _params.t      or 0
	_params.b      = _params.b      or 0
	_params.anchor = _params.anchor or cc.p(0.5, 0.5)

	-- preload mode
	if not _node then
		assert(_params.size)
		if BoxLayout.debug then
			_node = cc.LayerColor:create(cc.c4b(math.random(0,255),math.random(0,255),math.random(0,255),255))
			_node:ignoreAnchorPointForPosition(false)
			_node:setContentSize(_params.size)
		end
	end

	if _node then
		_node:setAnchorPoint(cc.p(0.5, 0.5))
		self:addChild(_node)
	end

	local item = nil
	item = {item=_node, params = _params}
	if _index then
		table.insert(self.item, _index, item)
	else
		table.insert(self.item, item)
	end

	return item
end

function BoxLayout:attach(_index, _node, _params)
	local item = assert(self.item[_index])

	if item.item then
		item.item:removeFromParent()
	end
	item.item = _node
	_node:setPosition(item.params.pos)
	_node:setAnchorPoint(cc.p(0.5, 0.5))
	self:addChild(_node)

	if _params then
		for k,v in pairs(_params) do
			item.params[k] = v
		end
	end
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
				_params.w = math.max(_params.w or v:getContentSize().width*_stripe, box:measure(_direction, _params.padding or 0).w)
			elseif _direction == cc.ui.UIScrollView.DIRECTION_VERTICAL and not _params.h then
				_params.h = math.max(_params.h or v:getContentSize().height*_stripe, box:measure(_direction, _params.padding or 0).h)
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

function BoxLayout:sortItem()
	local wight_cache = {}
	local min_index = - 99999
	local function get_weight(_item, _id)
		if not wight_cache[_id] then
			if _item then
				wight_cache[_id] = _item:onAutoLayoutGetSortWeight()
			else
				wight_cache[_id] = min_index
				min_index = min_index - 1
			end
		end
		return wight_cache[_id]
	end

	for i,v in ipairs(self.item) do
		v.__sort_id = i
	end
	table.sort( self.item, function(v1,v2)
		return get_weight(v1.item, v1.__sort_id) > get_weight(v2.item, v2.__sort_id)
	end )
end

function BoxLayout:getItems()
	return self.item
end

function BoxLayout:getItemByOffset(_offset)
	local offset = 0
	for i,v in ipairs(self.item) do
		if self.direction == cc.ui.UIScrollView.DIRECTION_VERTICAL then
			offset = offset + v.params.size.height
		elseif self.direction == cc.ui.UIScrollView.DIRECTION_HORIZONTAL then
			offset = offset + v.params.size.width
		end
		if offset > _offset then
			return i,v
		end
	end
	return #self.item, self.item[#self.item]
end

function BoxLayout:getItemByTag(_tag, _all)
	local items = {}
	for i,v in ipairs(self.item) do
		if v.params.tag and v.params.tag == _tag then
			if _all then
				table.insert(items, v)
			else
				return v
			end
		end
	end
	if _all then
		return items
	end
end

function BoxLayout:getItemSize(_id)
	local params = assert(self.item[_id]).params
	return cc.size(params.size.width + params.l +  params.r, params.size.height + params.t +  params.b) 
end

function BoxLayout:_calcItemSize(_item, _params)
	if not _item then
		return _params.size
	end

	_params.size = _item:getBoundingBox()
	_params.anchor = _item:getAnchorPoint()

	return _params.size
end

function BoxLayout:measure(_direction, _padding)
	local w,h = 0,0
	local size = nil
	for i,v in ipairs(self.item) do
		size = self:_calcItemSize(v.item, v.params)
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

function BoxLayout:relayout()
	self:layout(self.direction, self.params)
end

function BoxLayout:layout(_direction, _params)
	_params = _params or {}
	_params.padding = _params.padding or 0
	_params.align   = _params.align or display.CENTER

	self.direction = _direction
	self.params = _params
	
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
	local size, anchor
	for i,v in ipairs(self.item) do
		v.id = i
		size = v.params.size
		anchor = v.params.anchor
		y = _anchor.y * _params.h + (anchor.y - _anchor.y) * size.height
		x = x + v.params.l + size.width * anchor.x
		v.params.pos = cc.p(x,y)
		if v.item then v.item:setPosition(x,y) end
		x = x + size.width * (1-anchor.x) + v.params.r + _params.padding
	end
end

function BoxLayout:vlayout(_params, _h, _anchor)
	local x = 0
	local y = _h - (_anchor.y * (_params.h - _h))
	local size, anchor
	for i,v in ipairs(self.item) do
		v.id = i
		size = v.params.size
		anchor = v.params.anchor
		x = _anchor.x * _params.w + (1 - anchor.x - _anchor.x) * size.width
		y = y - (v.params.t + size.height * (1-anchor.y))
		v.params.pos = cc.p(x,y)
		if v.item then v.item:setPosition(x,y) end
		y = y - (size.height * anchor.y + v.params.b + _params.padding)
	end
end

return BoxLayout