#include <sourcemod>
#include <colors>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#pragma newdecls required
#define PluginPrefix "{green}[TecnoHard™]{default}"

ArrayList props;

public Plugin myinfo =
{
	name 			= "TecnoHard™ Restrinções Dust2",
	author		    = "AbNeR @CSB",
	description 	= "Restrinções como fundo e varanda na Dust2.",
	version 		= PLUGIN_VERSION,
	url 			= "http://www.tecnohardclan.com/forum/"
}

public void OnPluginStart(){

	props = new ArrayList();
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_team", PlayerJoinTeam);
	HookEvent("player_disconnect", PlayerJoinTeam);
	RegAdminCmd("refreshprops", CmdReloadProps, ADMFLAG_ROOT);
	CreateConVar("tecnohard_maprestrictions", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	
	char mapname[100];
	GetCurrentMap(mapname, sizeof(mapname))
	if(!StrEqual(mapname, "de_dust2"))
	{
		char filename[256];
		GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
		ServerCommand("sm plugins unload %s", filename);
	}
}

public Action PlayerJoinTeam(Handle ev, char[] name, bool dbroad){
	CreateTimer(0.1, ReloadPropsTime);
}

public Action CmdReloadProps(int client, int args){
	ReloadProps();
}

public Action ReloadPropsTime(Handle time){
	ReloadProps();
}

public Action EventRoundStart(Handle ev, char[] name, bool db){
	ReloadProps();
	
	char TipoRestrincao[50];
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	if(PlayerCount < 6)
		Format(TipoRestrincao, 100, "Só fundo.");
	else if(PlayerCount < 10)
		Format(TipoRestrincao, 100, "Fundo e Varanda.");
	
	if(!StrEqual(TipoRestrincao, ""))
		CPrintToChatAll("%s {lightgreen}%d{default}x{lightgreen}%d {default}- {green}%s", PluginPrefix, GetTeamClientCount(2), GetTeamClientCount(3), TipoRestrincao);
}

void ReloadProps(){
	DeleteAllProps();
	CreateProps();
}


void DeleteAllProps(){

	for(int i = 0;i < props.Length;i++){
		int Ent = props.Get(i);
		if(IsValidEntity(Ent))
			AcceptEntityInput(props.Get(i), "kill");
	}
	props.Clear();
}

void CreateProps(){
	props.Clear();
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv = new KeyValues("Positions");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/dust2_positions.ini");
	if(!FileToKeyValues(kv, path)) SetFailState("%s - dust2_positions.ini not found.", PluginPrefix);
	if(kv.GotoFirstSubKey())
	{
		do
		{
			float origin[3];
			float angles[3];
			int maxplayers;
			
			kv.GetVector("origin", origin);
			kv.GetVector("angles", angles);
			maxplayers = kv.GetNum("maxplayers", 0);
			
			if(PlayerCount <= maxplayers)
			{
				PrecacheModel("models/props_wasteland/exterior_fence001b.mdl",true);
				int Ent = CreateEntityByName("prop_physics_override"); 
			
				DispatchKeyValue(Ent, "physdamagescale", "0.0");
				DispatchKeyValue(Ent, "model", "models/props_wasteland/exterior_fence001b.mdl");

				DispatchSpawn(Ent);
				SetEntityMoveType(Ent, MOVETYPE_PUSH);
				
				TeleportEntity(Ent, origin, angles, NULL_VECTOR);
				props.Push(Ent);
			}
	
		}while(kv.GotoNextKey());
	}
	else
	{
		SetFailState("%s - Corrupted dust2_positions.ini", PluginPrefix);
	}
	delete kv;
}
