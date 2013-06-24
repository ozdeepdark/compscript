
------------------------------------------------------------

--KOD  BLOCKLARI
-----------------------------------------------------------



--Tests wether a file with the filename name exists. Returns true if it does and false if not
function fileExists(name)
   local f = io.open(name,'r');   --  io.open araştır !!!
   if (f ~= nil) then
		f:close();
		return true;
	else
		return false;
	end;
end;

--Downloads and installs the ProtLib API.
if(not fileExists('ProtLib')) then
	shell.run('pastebin', 'get', 's8GSFZrU', 'ProtLib');
end;
os.loadAPI('ProtLib');


--********************************************************************************
--değisken girebilmek için // error() araştır 

local howfar = tonumber(tArgs[1])
if howfar == nil then 
  print "Usage: "
  print "at <forward> [<height>] [<torches-every>]"
  print "*negative height disables ceiling fill"
  print "Place cobble or filler in slot 1"
  print "Place torches in slot 16"
  print "Place fuel in any other slot"
  error(" ",0)
end

