return {
  --Print log
  Log = function(self, mode, langTable, langCode, key, ...)
    local text = self:GetLangText(langTable, langCode, key, ...)
    --Print system message
    if mode == 'Normal' then
      CHAT_SYSTEM(text)
    --Print warning message (warning style on center screen)
    elseif mode == 'Warning' then
      ui.SysMsg(self:GetStyledText(text, {'#FF0000'}))
    --Print notice message (global shout style on center screen, system message)
    elseif mode == 'Notice' then
      local frame = ui.GetFrame('notice')
      local textObj = GET_CHILD(frame, 'text', 'ui::CRichText')
      local iconObj = GET_CHILD(frame, 'dungeon_msg', 'ui::CPicture')
       --Print message on center screen and system message
      CHAT_SYSTEM(self:GetStyledText(text, {'#FF0000'}))
      textObj:SetText(self:GetStyledText(text, {'@st55_a'}))
      textObj:SetOffset(0, 0)
      --Hide icon
      iconObj:ShowWindow(0)
      --Show message
      frame:Resize(frame:GetWidth(), textObj:GetHeight())
      frame:ShowWindow(1)
      frame:SetDuration(5.0)
    end
  end,


  --Return Multi-language
  GetLangText = function(self, langTable, langCode, key, ...)
    return self:GetPostPositionReplacedText(string.format(self:GetValue(langTable[langCode], key) or key, ...))
  end,


  --Return post-position added text (for korean)
  GetPostPositionReplacedText = function(self, text)
    local pattern = '{pp (.-) (.-)}'
    local tstart, tend = text:find(pattern)
    --Do not need translate post-position
    if not tstart then
      return text
    end
    --Add post-position
    local postfix1, postfix2 = text:match(pattern)
    local replacedText = self:AddPostPosition(text:sub(1, tstart - 1), postfix1, postfix2) .. text:sub(tend + 1)
    return self:GetPostPositionReplacedText(replacedText)
  end,


  --Return font-style added text
  GetStyledText = function(self, text, style)
    local styledText
    if not style or #style == 0 then
      styledText = text
    else
      local tags = ''
      for i, tag in ipairs(style) do
        tags = tags .. string.format('{%s}', tag)
      end
      styledText = string.format('%s%s%s', tags, text, string.rep('{/}', #style))
    end
    return styledText
  end,


  --Return image-print text
  GetImageText = function(self, image, width, height)
    return string.format('{img %s %d %d}', image, width, height)
  end,


  --Split text using delimiter
  Split = function(self, text, delimiter)
    local splitText = {}
    for match in text:gmatch('[^' .. delimiter .. ']+') do
      table.insert(splitText, match)
    end
    return splitText
  end,


  --Return object search result with given key
  GetValue = function(self, obj, key, delimiter)
    --Handling invalid parameter exceptions
    if not obj or not key or key == '' then
      return nil
    end
    delimiter = delimiter or '.'
    local keys = self:Split(key, delimiter)
    for i, key in ipairs(keys) do
      obj = obj[key]
      --If the object cannot search
      if not obj then
        return nil
      end
    end
    return obj
  end,


  --Return the last character in Unicode bytes
  GetLastCharByUnicode = function(self, text)
    if text:len() < 3 then
      return 0
    end
    return (text:byte(-3) - 0xE0) * 0x1000 + (text:byte(-2) - 0x80) * 0x40 + text:byte(-1) - 0x80
  end,


  --Return if character have final consonant (for korean)
  HasFinalConsonant = function(self, code)
    if code < 0xAC00 or code > 0xD7A3 then
      return false
    end
    return (code - 0xAC00) % 28 > 0
  end,


  --Add post-position (for korean)
  AddPostPosition = function(self, text, postfix1, postfix2)
    local lastchr = self:GetLastCharByUnicode(text)
    if self:HasFinalConsonant(lastchr) then
      text = text .. postfix1
    else
      text = text .. postfix2
    end
    return text
  end,


  --Return game timestamp
  GetGameTime = function(self)
    local serverTime = geTime.GetServerSystemTime()
    local gameTime = os.time({
        year  = serverTime.wYear,
        month = serverTime.wMonth,
        day   = serverTime.wDay,
        hour  = serverTime.wHour,
        min   = serverTime.wMinute,
        sec   = serverTime.wSecond
      })
    return gameTime
  end,


  --Add seconds to timestamp
  AddTime = function(self, time, addTime)
    local origin = os.date('*t', time)
    origin.sec = origin.sec + addTime
    return os.time(origin)
  end,


  --Return valid time test result
  IsExpiredTime = function(self, time, expireTime)
    return self:GetGameTime() > self:AddTime(time, expireTime)
  end,


  --Return if two times equal test within the error time
  IsEqualTime = function(self, time1, time2, errorTime)
    return self:AddTime(time2, -errorTime) < time1 and time1 < self:AddTime(time2, errorTime)
  end,


  --Return timestamp to string
  TimestampToString = function(self, timestamp)
    local timetable = os.date('*t', timestamp)
    return string.format(
      '%02d/%02d %02d:%02d:%02d',
      timetable.month,
      timetable.day,
      timetable.hour,
      timetable.min,
      timetable.sec)
  end,


  --Return the time expressed in Day/Hour/Minute/Second
  TimeToString = function(self, time)
    local d, h, m, s = GET_DHMS(math.floor(time))
    if d > 0 then
      return ScpArgMsg('{Day}', 'Day', d)
    elseif h > 0 then
      return ScpArgMsg('{Hour}', 'Hour', h)
    elseif m > 0 then
      return ScpArgMsg('{Min}', 'Min', m)
    end
    return ScpArgMsg('{Sec}', 'Sec', s)
  end,


  --Add group box to parent object
  GetGroupBox = function(self, parent, ctrlName, width, height, left, top)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    width = width or 10
    height = height or 4
    left = left or 0
    top = top or 0
    --Add group box
    local groupbox = tolua.cast(parent:CreateOrGetControl('groupbox', ctrlName, left, top, width, height), 'ui::CGroupBox')
    groupbox:SetGravity(ui.LEFT, ui.TOP)
    groupbox:EnableHitTest(0)
    groupbox:EnableDrawFrame(0)
    groupbox:ShowWindow(1)
    return groupbox
  end,


  --Add picture to parent object
  GetPicture = function(self, parent, ctrlName, width, height, left, top, image)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    width = width or 0
    height = height or 0
    left = left or 0
    top = top or 0
    --Add picture
    local picture = tolua.cast(parent:CreateOrGetControl('picture', ctrlName, left, top, width, height), 'ui::CPicture')
    picture:SetImage(image)
    picture:SetGravity(ui.LEFT, ui.TOP)
    picture:SetEnableStretch(1)
    picture:EnableHitTest(0)
    picture:ShowWindow(1)
    return picture
  end,


  --Add button to parent object
  GetButton = function(self, parent, ctrlName, width, height, left, top, image, tooltip)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    width = width or 0
    height = height or 0
    left = left or 0
    top = top or 0
    --Add button
    local button = tolua.cast(parent:CreateOrGetControl('button', ctrlName, left, top, width, height), 'ui::CButton')
    if image then button:SetImage(image) end
    if tooltip then button:SetTextTooltip(tooltip) end
    button:SetOverSound('button_over')
    button:SetClickSound('button_click_big')
    button:SetAnimation('MouseOnAnim', 'btn_mouseover')
    button:SetAnimation('MouseOffAnim', 'btn_mouseoff')
    button:SetGravity(ui.LEFT, ui.TOP)
    button:EnableImageStretch(true)
    button:Resize(width, height)
    button:EnableHitTest(1)
    button:ShowWindow(1)
    return button
  end,


  --Add check box to parent object
  GetCheckBox = function(self, parent, ctrlName, left, top, text, style)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    left = left or 0
    top = top or 0
    --Add check box
    local checkbox = tolua.cast(parent:CreateOrGetControl('checkbox', ctrlName, left, top, 100, 30), 'ui::CCheckBox')
    if text then checkbox:SetText(self:GetStyledText(text, style)) end
    checkbox:SetOverSound('button_over')
    checkbox:SetClickSound('button_click_big')
    checkbox:SetAnimation('MouseOnAnim', 'btn_mouseover')
    checkbox:SetAnimation('MouseOffAnim', 'btn_mouseoff')
    checkbox:SetGravity(ui.LEFT, ui.TOP)
    checkbox:EnableHitTest(1)
    checkbox:ShowWindow(1)
    return checkbox
  end,


  --Add label to parent object
  GetLabel = function(self, parent, ctrlName, left, top, text, style)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    left = left or 0
    top = top or 0
    style = style or {}
    --Add label
    local label = tolua.cast(parent:CreateOrGetControl('richtext', ctrlName, left, top, 10, 4), 'ui::CRichText')
    if text then label:SetText(self:GetStyledText(text, style)) end
    label:SetGravity(ui.LEFT, ui.TOP)
    label:EnableHitTest(0)
    label:ShowWindow(1)
    return label
  end,


  --Add label line to parent object
  GetLabelLine = function(self, parent, ctrlName, width, left, top)
    --Handling invalid parameter exceptions
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --Set parameter defaults
    width = width or 10
    left = left or 0
    top = top or 0
    --Add label line
    local labelline = parent:CreateOrGetControl('labelline', ctrlName, left, top, width, 10)
    labelline:SetSkinName('labelline2')
    labelline:SetGravity(ui.LEFT, ui.TOP)
    labelline:EnableHitTest(0)
    labelline:ShowWindow(1)
    return labelline
  end
}
