--
-- Author: wangbilt@gmail.com
-- Date: 2016-03-02 14:31:44
--


local MMDataModel = class("MMDataModel")

function MMDataModel:ctor()
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
	self.data = {}
end

function MMDataModel:onGetSortWeight(_callfunc)
	self.sort_weight_callfunc = _callfunc
end

function MMDataModel:resortData()
	local wight_cache = {}
	local function get_weight(_data)
		local sort_id = _data.__sort_id
		if not wight_cache[sort_id] then
			wight_cache[sort_id] = self.sort_weight_callfunc(_data.userdata, sort_id)
		end
		return wight_cache[sort_id]
	end
	for i,v in ipairs(self.data) do
		v.__sort_id = i
	end
	table.sort( self.data, function(v1,v2)
		return get_weight(v1) > get_weight(v2)
	end )

	self:_reRef()
end

function MMDataModel:_reRef()
	for i,v in ipairs(self.data) do
		self.data[v.tag] = i
	end
end

function MMDataModel:push(_tag, _data)
	assert(type(_tag) ~= "number")
	assert(type(_data) == "table")
	assert(self.data[_tag] == nil, "Already exists a key named :".._tag)

	self.data[_tag] = #self.data + 1
	table.insert(self.data, {tag = _tag, userdata = _data})
    self:dispatchEvent{ name  = "push", tag = _tag, userdata = _data }
end

function MMDataModel:count()
	return #(self.data)
end

function MMDataModel:getData(_id)
	assert(_id >= 1 and _id <= #self.data)
	return self.data[_id]
end

function MMDataModel:getDataList()
	return self.data
end

function MMDataModel:getField(_tag, _key)
	local index = assert(self.data[_tag])
	return self.data[index].userdata[_key]
end

function MMDataModel:setField(_key, _value)
	for i,v in ipairs(self.data) do
		v.userdata[_key] = _value
    	self:dispatchEvent{ name  = "field_change", index = i, data = v, key = _key, value = _value, multi = true }
	end
end

function MMDataModel:setFieldByFilter(_key, _value, _callfunc)
	for i,v in ipairs(self.data) do
		if _callfunc(i,v) then
			v.userdata[_key] = _value
	    	self:dispatchEvent{ name  = "field_change", index = i, data = v, key = _key, value = _value, multi = true }
	    end
	end
end

function MMDataModel:setFieldByTag(_tag, _key, _value)
	local index = assert(self.data[_tag])
	self.data[index].userdata[_key] = _value

    self:dispatchEvent{ name  = "field_change", index = index, data = self.data[index], key = _key, value = _value }
end

function MMDataModel:removeItem(_tag)
	for ii,vv in ipairs(self.data) do
		if vv.tag == _tag then
			self:dispatchEvent{ name  = "remove", index = ii, tag = _tag, value = vv }
			table.remove(self.data, ii)
			break
		end
	end
	self:_reRef()
end

function MMDataModel:removeItems(_tag_list)
	for i,v in pairs(_tag_list) do
		self.data[v] = nil
		for ii,vv in ipairs(self.data) do
			if vv.tag == v then
    			self:dispatchEvent{ name  = "remove", index = ii, tag = v, value = vv }
				table.remove(self.data, ii)
				break
			end
		end
	end
	self:_reRef()
end

return MMDataModel