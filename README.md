# [CS:GO] AbNeR MapRestrictions
  ![ScreenShot](http://oi65.tinypic.com/15hxvdt.jpg)

  > Plugin to restrict areas in maps depending on the number of players.
  > For a while only **de_dust2** is configured in this plugin, you can try change positions in **sourcemod/data/de_dust2.ini** or even create new files for other maps like **de_inferno.ini** and configure the positions following the example of de_dust2.ini. (This will take some work)
 In future i will make some menu to save custom positions of maps in game (I would accept help to do it :D)
 
 > Messages are configured in  **sourcemod/data/de_dust2.ini** in **"Messages"** section of the file. Configure this as you wish following the model.
 
``` 
  "Messages"{
		"1"
		{
			"lessthan"		"6"
			"message"		"Long Only"
		}
		"2"
		{
			"morethan"		"5"
			"lessthan"		"10"
			"message"		"Cat and Long Only."
		}
		"3"
		{
			"morethan"		"9"
			"message"		"AllMap"
		}
	}
 ``` 
  For now I set de_dust2 map to
  
 - Less than 6 players allows Long only.
 - More than 5 players and less than 10 allows Cat and Long.
 - More than 9 players allows entire map
 
# Support
- AlliedModders: https://forums.alliedmods.net/showthread.php?p=2437271#post2437271
- TecnoHard Clan: http://www.tecnohardclan.com/forum/index.php/topic/5695-csgo-tecnohard-dust2/
 
