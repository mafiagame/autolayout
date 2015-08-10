--
-- Author: justbilt
-- Date: 2015-02-25 14:41:30
--


local BoxLayout = import(".BoxLayout")

local AutoLayout = class("AutoLayout", cc.ui.UIScrollView)

function AutoLayout:ctor()
	AutoLayout.super.ctor(self)
	self.box = BoxLayout.new()
	self.box:setAnchorPoint(cc.p(0.0,0))
	self:addScrollNode(self.box)
end

function AutoLayout:setSizeSuitEnable(_enbale)
	self.sizeSuitEnbale = _enbale
	self:refreshSizeSuit()
end

function AutoLayout:clear()
	self.box:clear()
end

function AutoLayout:count()
	return self.box:count()
end

function AutoLayout:insert(_item, _index, _params)
	return self.box:insert(_item, _index, _params)
end

function AutoLayout:push(_item, _params)
	return self.box:push(_item, _params)
end

function AutoLayout:pop()
	self.box:pop()
end

function AutoLayout:removeByTag(_tag, _all)
	self.box:removeByTag(_tag, _all)
end

function AutoLayout:remove(_id)
	self.box:remove(_id)
end

function AutoLayout:getViewSize()
	return self:getContentSize()
end

function AutoLayout:setViewSize(_size)
	self:setViewRect(cc.rect(0,0,_size.width,_size.height))
	self:setContentSize(_size)
end

function AutoLayout:gotoBegin(_ani)
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		self:setContentOffset(-self.box:getContentSize().height+self:getViewSize().height, _ani)
	else
		self:setContentOffset(0, _ani)
	end
end

function AutoLayout:gotoEnd(_ani)
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		self:setContentOffset(math.max(0, self:getViewSize().height -self.box:getContentSize().height ), _ani)
	else
		self:setContentOffset(-self.box:getContentSize().width+self:getViewSize().width, _ani)
	end
end

function AutoLayout:setContentOffset(offset, animated)
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		self.scrollNode:setPositionY(offset)
	else
		self.scrollNode:setPositionX(offset)
	end	
end

function AutoLayout:pushGrid(_item_list, _stripe, _direction, _params, _padding)
	return self.box:pushGrid(_item_list, _stripe, _direction, _params, _padding)
end

function AutoLayout:isNeedScroll()
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		return self.box:getContentSize().height>self:getViewSize().height
	else
		return self.box:getContentSize().width>self:getViewSize().width
	end	
end

function AutoLayout:refreshSizeSuit()
	if self.sizeSuitEnbale then
		self:setTouchEnabled(self:isNeedScroll())
	else
		self:setTouchEnabled(true)
	end	
end

function AutoLayout:layout(_movetoend, _ani)
	-- 计算偏移,重新布局
	local length = 0
	local offset = 0
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		length = self.box:getContentSize().height
		offset = self.box:getPositionY()
		self.box:layout(self:getDirection(), {w=self:getViewSize().width})
	else
		length = self.box:getContentSize().width
		offset = self.box:getPositionX()
		self.box:layout(self:getDirection(), {h=self:getViewSize().height})
	end
	self:addTouchNode()

	-- 调整位置
	if _movetoend == true then
		self:gotoEnd(_ani)
	elseif _movetoend == false then
		self:gotoBegin(_ani)
	else
		if not self.layouted then
			self:gotoBegin(_ani)
		else
			if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
				self:setContentOffset(-(self.box:getContentSize().height-length)+offset, _ani)
			else
				self:setContentOffset(-(self.box:getContentSize().width-length)+offset, _ani)
			end	
		end
	end

	self:refreshSizeSuit()

	self.layouted = true
end


return AutoLayout