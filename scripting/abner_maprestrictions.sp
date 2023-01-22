#include <sourcemod>
#include <colors>
#include <sdktools>
#include <cstrike>

#include "maprestrictions/utils.sp"

#include "maprestrictions/structs.sp"
#include "maprestrictions/read-data.sp"
#include "maprestrictions/players.sp"

// Menus
#include "maprestrictions/menus/main.sp"
#include "maprestrictions/menus/restriction-groups.sp"
#include "maprestrictions/menus/restriction-group-detail.sp"
#include "maprestrictions/menus/fence.sp"

#define PLUGIN_VERSION "1.2.2"
#pragma newdecls required

#define FENCE "models/props_wasteland/exterior_fence001b.mdl"

ArrayList props;

Handle	  g_AutoReload;
Handle	  g_Message;


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
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	CreateConVar("abner_maprestrictions_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_REPLICATED);
}

public Action Command_Say(int client, int args)
{
	char sText[255];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	Players_OnSay(client, sText);
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;

		int entity = g_PlayerState[i].SpawningEntity;
		if (IsPlayerAlive(i) && entity != -1 && IsValidEntity(entity))
		{
			float position[3];
			float angles[3];
			GetPropPositionByClient(i, position, angles);
			MoveRestriction(entity, position, angles);
		}
	}
}

public void OnMapStart()
{
	if (PrecacheModel(FENCE, true) == 0)
		SetFailState("[AbNeR MapRestrictions] - Error precaching model '%s'", FENCE);

	Player_ClearAll();
	Data_OnMapStart();
	ReloadProps();	
}



public void OnClientPutInServer(int client)
{	
	Player_PutIn(client);
}

public Action CommandRestrictions(int client, int args)
{
	Menus_ShowMainMenu(client);
	return Plugin_Continue;
}


void MoveRestriction(int entity, float position[3], float angles[3])
{
	TeleportEntity(entity, position, angles, NULL_VECTOR);
}

void GetPropPositionByClient(int client, float proppos[3], float propang[3])
{
	float clientang[3];
	GetClientEyeAngles(client, clientang);

	propang	   = clientang;
	propang[0] = 0.0;
	propang[1] += 180.0;

	float direction[3];
	GetAngleVectors(clientang, direction, NULL_VECTOR, NULL_VECTOR);

	float startpos[3];
	GetClientEyePosition(client, startpos);

	ScaleVector(direction, 150.0);
	AddVectors(startpos, direction, proppos);
	proppos[2] += 50.0;
}



public Action PlayerJoinTeam(Handle ev, char[] name, bool dbroad)
{
	if (GetConVarInt(g_AutoReload) == 1)
		CreateTimer(0.1, ReloadPropsTime);
	return Plugin_Continue;
}

public Action CmdReloadProps(int client, int args)
{
	LoadRestrictionGroups();
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
	Player_ClearAll();
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

void GetPositionName(int client, char[] buffer, int size)
{
	GetEntPropString(client, Prop_Send, "m_szLastPlaceName", buffer, size);
}

void CreateProps()
{
	props.Clear();

	int playerCount = GetTeamClientCount(3) + GetTeamClientCount(2);

	for (int i = 0; i < g_RestrictionGroups.Length; i++)
	{
		RestrictionGroup group;
		GetGroup(i, group);

		if (group.MaxPlayers <= playerCount)
			continue;

		for (int j = 0; j < group.Restrictions.Length; j++)
		{
			Restriction restriction;
			group.Restrictions.GetArray(j, restriction, sizeof(restriction));

			int entity = SpawnRestriction(restriction.Position, restriction.Angle);
			props.Push(entity);
		}
	}

	// char mapname[100];
	// GetCurrentMap(mapname, sizeof(mapname));
	// props.Clear();

	// int		  PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	// KeyValues kv		  = new KeyValues("Positions");

	// char	  path[PLATFORM_MAX_PATH];
	// BuildDataPath(path, mapname);

	// if (!FileToKeyValues(kv, path))
	// {
	// 	return;
	// }

	// if (kv.JumpToKey("Positions") && kv.GotoFirstSubKey())
	// {
	// 	do
	// 	{
	// 		int MoreThan = kv.GetNum("morethan", 0);
	// 		int LessThan = kv.GetNum("lessthan", 0);

	// 		if (kv.GotoFirstSubKey())
	// 		{
	// 			do
	// 			{
	// 				float origin[3];
	// 				float angles[3];
	// 				kv.GetVector("origin", origin);
	// 				kv.GetVector("angles", angles);

	// 				if (PlayerCount > MoreThan && (LessThan == 0 || PlayerCount < LessThan))
	// 				{
	// 					int entity = SpawnRestriction(origin, angles);
	// 					props.Push(entity);
	// 				}
	// 			}
	// 			while (kv.GotoNextKey());
	// 			kv.GoBack();
	// 		}
	// 		else
	// 		{
	// 			SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	// 		}
	// 	}
	// 	while (kv.GotoNextKey());
	// }
	// else
	// {
	// 	SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	// }

	// kv.Rewind();

	// if (kv.JumpToKey("MapPositions") && kv.GotoFirstSubKey())
	// {
	// 	do
	// 	{
	// 		char sectionName[1024];
	// 		kv.GetSectionName(sectionName, sizeof(sectionName));

	// 		int	 from = kv.GetNum("from", 0);

	// 		char positions[20][255];
	// 		ExplodeString(sectionName, ";", positions, sizeof(positions), sizeof(positions[]));

	// 		for (int i = 0; i < sizeof(positions); i++)
	// 		{
	// 			if (StrEqual(positions[i], ""))
	// 				continue;

	// 			TrimString(positions[i]);

	// 			if (PlayerCount < from)
	// 				for (int j = 1; j <= MaxClients; j++)
	// 				{
	// 					if (IsValidClient(j) && IsPlayerAlive(j))
	// 					{
	// 						char sLocation[255];
	// 						GetPositionName(j, sLocation, sizeof(sLocation));

	// 						if (StrEqual(sLocation, positions[i], false))
	// 						{
	// 							LogMessage("TP min player %N", j);
	// 							CS_RespawnPlayer(j);
	// 						}
	// 					}
	// 				}
	// 		}
	// 	}
	// 	while (kv.GotoNextKey());
	// }

	// delete kv;
}