--
-- Author: wangbilt@gmail.com
-- Date: 2015-08-07 10:16:55
--


local DropRefreshLayout = class("DropRefreshLayout", import(".AutoLayout"))

function DropRefreshLayout:ctor()
	DropRefreshLayout.super.ctor(self)

	self:setNodeEventEnabled(true)
end

function DropRefreshLayout:getBox()
	if not self.isLoading then
		return DropRefreshLayout.super.getBox(self)
	end
	return self.scrollNode:getCascadeBoundingBox()
end

local tmpMoveStartEnd = nil
local tmpLoad = nil
function DropRefreshLayout:onTouch_(event)
	if not self.isLoading and self.isEnableLoadMore then
		if "began" == event.name then
			tmpMoveStartEnd = self.box:getPositionY() >= 0
			print(self.box:getPositionY())
			self.dropNode:setVisible(self:isNeedScroll() and tmpMoveStartEnd)
		end
		if tmpMoveStartEnd then
			if "moved" == event.name then
				local load = self.box:getPositionY() > self.dropNode:getContentSize().height
				if tmpLoad ~= load then
					if load then
						self.loadMoreCallfunc("over")
					else
						self.loadMoreCallfunc("begin")
					end
					tmpLoad = load
				end
			elseif "ended" == event.name then
				if self.box:getPositionY() > self.dropNode:getContentSize().height then
					self.loadMoreCallfunc("end")
					self.isLoading = true
				end
			end
		end
	end

	return DropRefreshLayout.super.onTouch_(self, event)
end


function DropRefreshLayout:disable()
	self.isEnableLoadMore = false
	self.loadMoreCallfunc = nil
	self.dropNode:removeFromParent()
	self.dropNode:release()
	self.dropNode = nil
	self.isLoading = false
	self:gotoEnd()
end

function DropRefreshLayout:enable(_node, _callfunc)
	self.dropNode = _node
	self.dropNode:retain()
	self.dropNode:setVisible(false)

	self.isEnableLoadMore = true
	self.loadMoreCallfunc = function(_action)
    	if _action == "begin" then
    		self.dropNode:dropBegin()
    	elseif _action == "over" then
    		self.dropNode:dropOver()
    	elseif _action == "reset" then
    		self.dropNode:reset()
    	elseif _action == "end" then
    		self.dropNode:dropEnd()
		    _callfunc()
    	end
    end
end

function DropRefreshLayout:layout(_movetoend, _ani)
	self.isLoading = false
	if self.dropNode then
		self.loadMoreCallfunc("reset")
	end
	
	DropRefreshLayout.super.layout(self, _movetoend, _ani)

	if self.dropNode then
		if not self.dropNode:getParent() then
		    self.dropNode:addTo(self.box,99999)
			    :align(display.CENTER_TOP)
		end
		self.dropNode:setPositionX(self.box:getContentSize().width/2)
	end	
end


function DropRefreshLayout:onExit()
	if self.dropNode then	
		self.dropNode:release()
		self.dropNode = nil
	end
end


return DropRefreshLayout