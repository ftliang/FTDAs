function data = parsestr(datastr)
%PARSESTR 解析八位半万用表返回的字符串数据
%   --DATASTR 输入字符串
%   --DATA 字符串解析结果
    strarray = regexp(datastr,'E');
    len = length(strarray);
    data = zeros(1,len);
    data(1) = str2double(datastr(1:strarray(1)+3));
    for k = 2:len
        data(k) = str2double(datastr(strarray(k-1)+4:strarray(k)+3));
    end
end

