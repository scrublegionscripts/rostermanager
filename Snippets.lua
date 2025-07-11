-- if db.frame then

-- Convert from old settings to new

-- odb.frame = db.frame

-- if odb.frame.xOffset and odb.frame.yOffset then

-- odb.frame.xOffset = odb.frame.xOffset + GetScreenWidth() - (odb.frame.width or defaultWidth) / 2

-- odb.frame.yOffset = odb.frame.yOffset + GetScreenHeight()

-- end

-- db.frame = nil

-- end

-- if odb.frame then

-- xOffset, yOffset = odb.frame.xOffset, odb.frame.yOffset

-- end

-- if not (xOffset and yOffset) then

-- xOffset = GetScreenWidth() / 2

-- yOffset = GetScreenHeight() - defaultHeight / 2

 -- end

 -- frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", xOffset, yOffset)

 -- frame:Hide()