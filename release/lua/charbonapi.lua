return {
  --로그 출력
  Log = function(self, mode, langTable, langCode, key, ...)
    local text = self:GetLangText(langTable, langCode, key, ...)
    --시스템 메시지 출력
    if mode == 'Normal' then
      CHAT_SYSTEM(text)
    --경고 메시지 출력
    elseif mode == 'Warning' then
      ui.SysMsg(self:GetStyledText(text, {'#FF0000'}))
    --알림 메시지 출력
    elseif mode == 'Notice' then
      local frame = ui.GetFrame('notice')
      local textObj = GET_CHILD(frame, 'text', 'ui::CRichText')
      local iconObj = GET_CHILD(frame, 'dungeon_msg', 'ui::CPicture')
       --시스템 메시지와 화면 중앙에 메시지 출력
      CHAT_SYSTEM(self:GetStyledText(text, {'#FF0000'}))
      textObj:SetText(self:GetStyledText(text, {'@st55_a'}))
      textObj:SetOffset(0, 0)
      --아이콘 숨기기
      iconObj:ShowWindow(0)
      --메시지 표시
      frame:Resize(frame:GetWidth(), textObj:GetHeight())
      frame:ShowWindow(1)
      frame:SetDuration(5.0)
    end
  end,


  --다국어 텍스트 반환
  GetLangText = function(self, langTable, langCode, key, ...)
    return self:GetPostPositionReplacedText(string.format(self:GetValue(langTable[langCode], key) or key, ...))
  end,


  --조사가 추가된 텍스트 반환
  GetPostPositionReplacedText = function(self, text)
    local pattern = '{pp (.-) (.-)}'
    local tstart, tend = text:find(pattern)
    --조사 변환이 필요없는 경우
    if not tstart then
      return text
    end
    --조사 추가
    local postfix1, postfix2 = text:match(pattern)
    local replacedText = self:AddPostPosition(text:sub(1, tstart - 1), postfix1, postfix2) .. text:sub(tend + 1)
    return self:GetPostPositionReplacedText(replacedText)
  end,


  --스타일이 추가된 텍스트 반환
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


  --이미지로 출력되는 텍스트 반환
  GetImageText = function(self, image, width, height)
    return string.format('{img %s %d %d}', image, width, height)
  end,


  --문자열 분할
  Split = function(self, text, delimiter)
    local splitText = {}
    for match in text:gmatch('[^' .. delimiter .. ']+') do
      table.insert(splitText, match)
    end
    return splitText
  end,


  --주어진 키로 오브젝트 탐색 결과 반환
  GetValue = function(self, obj, key, delimiter)
    --잘못된 매개변수 예외 처리
    if not obj or not key or key == '' then
      return nil
    end
    delimiter = delimiter or '.'
    local keys = self:Split(key, delimiter)
    for i, key in ipairs(keys) do
      obj = obj[key]
      --오브젝트를 더 이상 탐색할 수 없는 경우
      if not obj then
        return nil
      end
    end
    return obj
  end,


  --마지막 글자를 유니코드 바이트로 반환
  GetLastCharByUnicode = function(self, text)
    if text:len() < 3 then
      return 0
    end
    return (text:byte(-3) - 0xE0) * 0x1000 + (text:byte(-2) - 0x80) * 0x40 + text:byte(-1) - 0x80
  end,


  --글자가 종성을 가지고 있는지 확인
  HasFinalConsonant = function(self, code)
    if code < 0xAC00 or code > 0xD7A3 then
      return false
    end
    return (code - 0xAC00) % 28 > 0
  end,


  --조사 추가
  AddPostPosition = function(self, text, postfix1, postfix2)
    local lastchr = self:GetLastCharByUnicode(text)
    if self:HasFinalConsonant(lastchr) then
      text = text .. postfix1
    else
      text = text .. postfix2
    end
    return text
  end,


  --게임 시간 반환
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


  --시간 덧셈 결과 반환
  AddTime = function(self, time, addTime)
    local origin = os.date('*t', time)
    origin.sec = origin.sec + addTime
    return os.time(origin)
  end,


  --유효 시간 검사 결과 반환
  IsExpiredTime = function(self, time, expireTime)
    return self:GetGameTime() > self:AddTime(time, expireTime)
  end,


  --오차 시간 이내로 같은 시간인지 확인 결과 반환
  IsEqualTime = function(self, time1, time2, errorTime)
    return self:AddTime(time2, -errorTime) < time1 and time1 < self:AddTime(time2, errorTime)
  end,


  --문자열로 표현된 시간 반환
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


  --일/시간/분/초로 표현된 시간 반환
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


  --그룹 박스 추가
  GetGroupBox = function(self, parent, ctrlName, width, height, left, top)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    width = width or 10
    height = height or 4
    left = left or 0
    top = top or 0
    --그룹 박스 추가
    local groupbox = tolua.cast(parent:CreateOrGetControl('groupbox', ctrlName, left, top, width, height), 'ui::CGroupBox')
    groupbox:SetGravity(ui.LEFT, ui.TOP)
    groupbox:EnableHitTest(0)
    groupbox:EnableDrawFrame(0)
    groupbox:ShowWindow(1)
    return groupbox
  end,


  --사진 추가
  GetPicture = function(self, parent, ctrlName, width, height, left, top, image)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    width = width or 0
    height = height or 0
    left = left or 0
    top = top or 0
    --사진 추가
    local picture = tolua.cast(parent:CreateOrGetControl('picture', ctrlName, left, top, width, height), 'ui::CPicture')
    picture:SetImage(image)
    picture:SetGravity(ui.LEFT, ui.TOP)
    picture:SetEnableStretch(1)
    picture:EnableHitTest(0)
    picture:ShowWindow(1)
    return picture
  end,


  --버튼 추가
  GetButton = function(self, parent, ctrlName, width, height, left, top, image, tooltip)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    width = width or 0
    height = height or 0
    left = left or 0
    top = top or 0
    --버튼 추가
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


  --체크 박스 추가
  GetCheckBox = function(self, parent, ctrlName, left, top, text, style)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    left = left or 0
    top = top or 0
    --체크 박스 추가
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


  --라벨 추가
  GetLabel = function(self, parent, ctrlName, left, top, text, style)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    left = left or 0
    top = top or 0
    style = style or {}
    --라벨 추가
    local label = tolua.cast(parent:CreateOrGetControl('richtext', ctrlName, left, top, 10, 4), 'ui::CRichText')
    if text then label:SetText(self:GetStyledText(text, style)) end
    label:SetGravity(ui.LEFT, ui.TOP)
    label:EnableHitTest(0)
    label:ShowWindow(1)
    return label
  end,


  --구분선 추가
  GetLabelLine = function(self, parent, ctrlName, width, left, top)
    --잘못된 매개변수 예외 처리
    if not parent or not ctrlName or ctrlName == '' then
      return nil
    end
    --매개변수 기본값 설정
    width = width or 10
    left = left or 0
    top = top or 0
    --구분선 추가
    local labelline = parent:CreateOrGetControl('labelline', ctrlName, left, top, width, 10)
    labelline:SetSkinName('labelline2')
    labelline:SetGravity(ui.LEFT, ui.TOP)
    labelline:EnableHitTest(0)
    labelline:ShowWindow(1)
    return labelline
  end
}
