# [CS:GO] AbNeR MapRestrictions
  ![csgo_2019-02-01_07-33-41](https://user-images.githubusercontent.com/14078661/52115131-0275ca80-25f5-11e9-903e-e3cb94bb8850.jpg)


  > Plugin to restrict areas in maps depending on the number of players.
  
> I set de_dust2 map to
  
 - Less than 6 players allows Long only.
 - More than 5 players and less than 10 allows Cat and Long.
 - More than 9 players allows entire map
 
# Configuration

File **abner_maprestrictions.cfg** will be autocreated in **sourcemod/cfg** first time you run the plugin.

- **abner_maprestrictions_autorefresh** - Refresh props when player joins a team our disconnect.
- **abner_maprestrictions_msgs** - Show message when round starts.

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
 
 > For a while only **de_dust2** is configured in this plugin, you can try change positions in **sourcemod/data/de_dust2.ini** or even create new files for other maps like **de_inferno.ini** and configure the positions following the example of de_dust2.ini. (This will take some work)
 > In future i will make some menu to save custom positions of maps in game (I would accept help to do that :D)
 

