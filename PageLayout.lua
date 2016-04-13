--
-- Author: wangbilt@gmail.com
-- Date: 2015-08-10 10:17:16
--


local PageLayout = class("PageLayout", import(".AutoLayout"))

function PageLayout:ctor()
	PageLayout.super.ctor(self)

	self.current = 1
	self.is_move = false
	self.is_page_init = {}
end

function PageLayout:next()
	self:to(self.current + 1, true)
end

function PageLayout:prev()
	self:to(self.current - 1, true)
end

function PageLayout:setCallBack(_callfunc, _init_callfunc)
	self.callfunc = _callfunc
	self.init_callfunc = _init_callfunc
end

local tmpPos = 0
function PageLayout:onTouch_(event)
	if "began" == event.name then
		tmpPos = cc.p(event.x, event.y)
	elseif "ended" == event.name then
		local dis = 0
		local length = 0
		if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
			dis = event.y - tmpPos.y
			length = self:getViewSize().height
		else
			dis = tmpPos.x - event.x
			length = self:getViewSize().width
		end
		if math.abs(dis) >= length/5*1 then
			if dis > 0 then
				self:next()
			else
				self:prev()
			end
		end
	end
	return true
end

function PageLayout:to(_index, _ani)
	if _index < 1 or _index > self:count() or self.is_move then
		return false
	end

	if not self.is_page_init[_index] then
		if self.init_callfunc then
			self.init_callfunc(_index)
		end
		self.is_page_init[_index] = true
	end

	self.is_move = true
	self.current = _index

	local pos = cc.p(self.box:getItem(_index).params.pos)
	if self:getDirection() == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		pos.x = 0
		pos.y = -pos.y + self:getViewSize().width/2
	else
		pos.y = 0
		pos.x = -pos.x + self:getViewSize().width/2
	end	
	
	if _ani then
		self.scrollNode:runAction(cc.Sequence:create({
			cc.MoveTo:create(0.3, pos),
			cc.CallFunc:create(handler(self, self.onMoveDone)),
		}))
	else
		self.scrollNode:setPosition(pos)
		self:onMoveDone()
	end
end

function PageLayout:onMoveDone()
	self.is_move = false
	if self.callfunc then
		self.callfunc(self.current)
	end
end

function PageLayout:currentPageIndex()
	return self.current
end

function PageLayout:layout(_index)
	_index = _index or 1
	PageLayout.super.layout(self)
	self:to(_index, false)
end

return PageLayout