#include <sourcemod>
#include <colors>
#include <sdktools>

#define PLUGIN_VERSION "1.2.2"
#pragma newdecls required

#define FENCE "models/props_wasteland/exterior_fence001b.mdl"

ArrayList props;

Handle	  g_AutoReload;
Handle	  g_Message;

int		  g_SpawnRestriction[MAXPLAYERS + 1] = { -1, ... };

public Plugin myinfo =
{
	name		= "AbNeR Map Restrictions",
	author		= "abnerfs",
	description = "Area restrictions in maps.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/abnerfs/maprestrictions"


}

public void
	OnPluginStart()
{
	AutoExecConfig(true, "abner_maprestrictions");

	g_AutoReload = CreateConVar("abner_maprestrictions_autorefresh", "1", "Refresh props when player joins a team our disconnect.");
	g_Message	 = CreateConVar("abner_maprestrictions_msgs", "1", "Show message when round starts");

	props		 = new ArrayList();
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_team", PlayerJoinTeam);
	HookEvent("player_disconnect", PlayerJoinTeam);
	RegAdminCmd("refreshprops", CmdReloadProps, ADMFLAG_ROOT);
	RegAdminCmd("restrictions", CommandRestrictions, ADMFLAG_ROOT);
	CreateConVar("abner_maprestrictions_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_REPLICATED);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any propEntity)
{
	return entity > MaxClients && entity != propEntity;
}

float[] GetViewPoint(int client, int propEntity)
{
	float start[3];
	float angle[3];
	float end[3];

	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, angle);
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, propEntity);
	if (TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(end, INVALID_HANDLE);
		return end;
	}
	else {
		PrintToChat(client, "[SM] Could not spawn prop at that view positon!");
		end[0] = 0.0;
		end[1] = 0.0;
		end[2] = 0.0;
		return end;
	}
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_SpawnRestriction[i] > -1)
		{
			if (IsValidEntity(g_SpawnRestriction[i]))
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					float position[3];
					float angles[3];
					GetPropPositionByClient(i, position, angles, g_SpawnRestriction[i]);
					MoveRestriction(g_SpawnRestriction[i], position, angles);
				}
				else {
					AcceptEntityInput(g_SpawnRestriction[i], "kill");
					g_SpawnRestriction[i] = -1;
				}
			}
			else
			{
				g_SpawnRestriction[i] = -1;
			}
		}
	}
}

public void OnMapStart()
{
	if (PrecacheModel(FENCE, true) == 0)
		SetFailState("[AbNeR MapRestrictions] - Error precaching model '%s'", FENCE);

	CleanSpawningRestrictions();
}

void CleanSpawningRestrictions()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_SpawnRestriction[i] != -1 && IsValidEntity(g_SpawnRestriction[i]))
			AcceptEntityInput(props.Get(i), "kill");

		g_SpawnRestriction[i] = -1;
	}
}

public void OnClientPutInServer(int client)
{
	g_SpawnRestriction[client] = -1;
}

public Action CommandRestrictions(int client, int args)
{
	Menu menu = new Menu(Restrictions_Handler);
	menu.SetTitle("AbNeR Map restrictions");
	menu.AddItem("1", "Spawn restriction");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int Restrictions_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					if (IsPlayerAlive(param1))
					{
						ShowSpawnMenu(param1);
						ServerCommand("mp_ignore_round_win_conditions 1");
						SetEntProp(param1, Prop_Data, "m_takedamage", 0, 1);
						// disable SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
					}
				}
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

void MoveRestriction(int entity, float position[3], float angles[3])
{
	TeleportEntity(entity, position, angles, NULL_VECTOR);
}

void GetPropPositionByClient(int client, float viewpos[3], float propang[3], int propEntity)
{
	viewpos = GetViewPoint(client, propEntity);

	float clientang[3];
	GetClientEyeAngles(client, clientang);
	propang[1] += 180.0;
}

void ShowSpawnMenu(int client)
{
	float viewpos[3];
	float propang[3];
	GetPropPositionByClient(client, viewpos, propang, -1);
	g_SpawnRestriction[client] = SpawnRestriction(viewpos, propang);

	Menu menu				   = new Menu(SpawnMenuHandler);
	menu.SetTitle("Spawn menu");
	menu.AddItem("1", "Save prop");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SpawnMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					g_SpawnRestriction[param1] = -1;
				}
			}
		}

		case MenuAction_Cancel:
		{
			if (IsValidEntity(g_SpawnRestriction[param1]))
				AcceptEntityInput(g_SpawnRestriction[param1], "kill");

			g_SpawnRestriction[param1] = -1;
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

public Action PlayerJoinTeam(Handle ev, char[] name, bool dbroad)
{
	if (GetConVarInt(g_AutoReload) == 1)
		CreateTimer(0.1, ReloadPropsTime);
	return Plugin_Continue;
}

public Action CmdReloadProps(int client, int args)
{
	ReloadProps();
	return Plugin_Continue;
}

public Action ReloadPropsTime(Handle time)
{
	ReloadProps();
	return Plugin_Continue;
}

public Action EventRoundStart(Handle ev, char[] name, bool db)
{
	CleanSpawningRestrictions();
	ReloadProps();

	if (GetConVarInt(g_Message) != 1)
		return Plugin_Continue;
	PrintMessage();
	return Plugin_Continue;
}

void ReloadProps()
{
	DeleteAllProps();
	CreateProps();
}

void DeleteAllProps()
{
	for (int i = 0; i < props.Length; i++)
	{
		int Ent = props.Get(i);
		if (IsValidEntity(Ent))
			AcceptEntityInput(props.Get(i), "kill");
	}
	props.Clear();
}

stock void BuildDataPath(char[] path, char[] mapname)
{
	char		  enginePath[100];
	EngineVersion engine = GetEngineVersion();
	switch (engine)
	{
		case Engine_CSGO:
		{
			Format(enginePath, sizeof(enginePath), "csgo");
		}
		case Engine_CSS:
		{
			Format(enginePath, sizeof(enginePath), "css");
		}
		default:
		{
			Format(enginePath, sizeof(enginePath), "other");
		}
	}
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/abner_maprestrictions/%s/%s.ini", enginePath, mapname);
}

void PrintMessage()
{
	char mapname[100];
	GetCurrentMap(mapname, sizeof(mapname));
	int		  PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv		  = new KeyValues("Messages");

	char	  path[PLATFORM_MAX_PATH];
	BuildDataPath(path, mapname);

	if (!FileToKeyValues(kv, path)) return;
	if (kv.JumpToKey("Messages") && kv.GotoFirstSubKey())
	{
		do
		{
			char Message[500];
			int	 MoreThan = kv.GetNum("morethan", 0);
			int	 LessThan = kv.GetNum("lessthan", 0);
			kv.GetString("message", Message, sizeof(Message));
			if (!StrEqual(Message, "") && PlayerCount > MoreThan && (LessThan == 0 || PlayerCount < LessThan))
			{
				CPrintToChatAll("{green}[AbNeR Map Restrictions]{default} {lightgreen}%d{default}x{lightgreen}%d {default}- {green}%s", GetTeamClientCount(2), GetTeamClientCount(3), Message);
			}
		}
		while (kv.GotoNextKey());
	}
	else
	{
		SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	}
	delete kv;
}

int SpawnRestriction(float position[3], float angles[3])
{
	int entity = CreateEntityByName("prop_physics_override");

	DispatchKeyValue(entity, "physdamagescale", "0.0");
	DispatchKeyValue(entity, "model", FENCE);

	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_PUSH);

	MoveRestriction(entity, position, angles);
	return entity;
}

void CreateProps()
{
	char mapname[100];
	GetCurrentMap(mapname, sizeof(mapname));
	props.Clear();

	int		  PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv		  = new KeyValues("Positions");

	char	  path[PLATFORM_MAX_PATH];
	BuildDataPath(path, mapname);

	if (!FileToKeyValues(kv, path)) return;

	if (kv.JumpToKey("Positions") && kv.GotoFirstSubKey())
	{
		do
		{
			int MoreThan = kv.GetNum("morethan", 0);
			int LessThan = kv.GetNum("lessthan", 0);

			if (kv.GotoFirstSubKey())
			{
				do
				{
					float origin[3];
					float angles[3];
					kv.GetVector("origin", origin);
					kv.GetVector("angles", angles);

					if (PlayerCount > MoreThan && (LessThan == 0 || PlayerCount < LessThan))
					{
						int entity = SpawnRestriction(origin, angles);
						props.Push(entity);
					}
				}
				while (kv.GotoNextKey());
				kv.GoBack();
			}
			else
			{
				SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
			}
		}
		while (kv.GotoNextKey());
	}
	else
	{
		SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	}
	delete kv;
}