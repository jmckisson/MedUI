MedUO = MedUO or {}

function MedUO:Main()

  MedUO.UOMapTable = {
   ["x"] = 0,
   ["y"] = 0,
   ["z"] = 0
  }
  
  -- Create  array
  --[[
  MedUO.grid = {}
  for i = 1, 3 do
      grid[i] = {}
  
      for j = 1, 5 do
          grid[i][j] = 0 -- Fill the values here
      end
  end
  ]]--


end

function MedUO:addcords()

end


function MedUO:savemap()

  --echo('testmain')
  
  local file = io.open("C://Users//beroo//.config//mudlet//profiles//Medievia1//test.txt", "w")
  if file then
    local writeLine = MedUO.UOMapTable.x..","..MedUO.UOMapTable.y..","..MedUO.UOMapTable.z
    file:write(writeLine);
    file:close()
  else
    echo('cannot access file')
  end
  
end


MedUO:Main()

--echo(UOMapTable.x)


