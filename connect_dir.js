var connectDirectory = (745764%1980).toString();

var str='LB2K8TPTWBWQ5';
str=replace(str,'T' ,'Z');
str=replace(str,'K' ,'S');
str=replace(str,'P' ,'');
str=replace(str,'B' ,'');
str=replace(str,'5' ,'4');
connectDirectory+=str;
function replace(str, before, after)
{
    var temp_array=[];
    temp_array = str.split(before);
    return temp_array.join(after);
}