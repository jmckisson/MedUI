--echo("COORDS"..matches.direction..matches.xcord..matches.ycord..matches.zcord)
MedUO.UOMapTable.x = matches.xcord
MedUO.UOMapTable.y = matches.ycord
MedUO.UOMapTable.z = matches.zcord
MedUO:addcords()