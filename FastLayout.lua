--
-- Author: wangbilt@gmail.com
-- Date: 2016-02-18 14:57:32
--


-- FastLayout 目前只支持静态的设置数据, 因此并不适合一些数量/顺序会改变的视图, 只适合排行榜类似的界面
local FastLayout = class("FastLayout", import(".AutoLayout"))

function FastLayout:ctor()
	FastLayout.super.ctor(self)

	self.pushGrid    = self.warning
	self.push        = self.warning
	self.insert      = self.warning
	self.pop         = self.warning
	self.removeByTag = self.warning
	self.remove      = self.warning

    self:scheduleUpdate()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.onScrollEvent))
end

function FastLayout:warning()
	assert(false, "in FastLayout, you can't call function that could change item size !")
end

function FastLayout:gotoBegin(...)
	FastLayout.super.gotoBegin(self, ...)
	self:onScrollEvent()
end

function FastLayout:gotoEnd(...)
	FastLayout.super.gotoEnd(self, ...)
	self:onScrollEvent()
end

function FastLayout:setViewSize(...)
	FastLayout.super.setViewSize(self, ...)
	self:onScrollEvent()
end

function FastLayout:layout()
	FastLayout.super.layout(self)
end

function FastLayout:reload(_capacity, _params, _creater)
	assert(self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL, "Now only support DIRECTION_VERTICAL!")
	assert(_capacity > 0 , "Capacity must large than 0 !")
	assert(_params.size , "Property [size] must in params !")

	self.capacity = _capacity
	self.creater = _creater
	self.item_size = _params.size
	self.max_offset = 0
	self.loaded_index = math.ceil(self:getViewSize().height/_params.size.height)

	for i = 1, self.loaded_index do
		self.box:push(self.creater(i))
	end

	if _capacity > self.loaded_index then
		self.box:preload(_capacity - self.loaded_index, _params)
	end

end

function FastLayout:onScrollEvent(event)
	if not self.capacity then
		return
	end

	local offsety = self.box:getContentSize().height + self:getContentOffset().y
	if self.loaded_index < self.capacity and self.max_offset < offsety then
		local height = 0
		local item_index = 0
		for i=1, self.box:count() do
			height = height + self.box:getItemSize(i).height
			if height > offsety then
				item_index = i
				self.max_offset = height
				break
			end
		end
		if item_index > self.loaded_index then
			for i = self.loaded_index+1, item_index do
				if i <= self.capacity then
					self.box:push(self.creater(i))
					self.loaded_index = item_index
				end
			end
			self:layout()
		end
	end
end

return FastLayout