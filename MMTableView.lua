--
-- Author: justbilt
-- Date: 2016-02-09 22:53:54
--


local MMTableView = class("MMTableView", function( ... )
	return cc.TableView:create(cc.size(0,0))
end)

function MMTableView:ctor()
	self.cells = {}
	self:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)

	self:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
	self:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
	self:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
end

function MMTableView:init(_modle, _class)
	self.modle = _modle
	self.class = _class

	self.modle:addEventListener("field_change", function(event)
		local cell = self:cellAtIndex(event.index - 1)
		if cell then
			cell.view:onFieldChanged(event.key, event.value)
		end
	end)

	self.modle:addEventListener("remove", function(event)
		self:removeCellAtIndex(event.index - 1)
	end)

	self:reloadData()
end

function MMTableView:numberOfCellsInTableView()
	return self.modle:count()
end

function MMTableView:cellSizeForTable(table, idx)
	local size = self.class.designSize
	local cell = self:cellAtIndex(idx)
    if cell then
    	size = cell.view:getBoundingBox()
    end
	return size.height, size.width
end

function MMTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
    	cell = cc.TableViewCell:new()
    	cell.view = self.class.new()
    		:pos(self.class.designSize.width/2, self.class.designSize.height/2)
    		:addTo(cell)
    end
    cell.view:refresh(self.modle:getData(idx + 1), self.modle)

    return cell
end

return MMTableView