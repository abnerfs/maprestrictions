#include <sourcemod>
#include <colors>
#include <sdktools>

#define PLUGIN_VERSION "1.2.2"
#pragma newdecls required

ArrayList props;

Handle g_AutoReload;
Handle g_Message;

public Plugin myinfo =
{
	name 			= "AbNeR Map Restrictions",
	author		    = "abnerfs",
	description 	= "Area restrictions in maps.",
	version 		= PLUGIN_VERSION,
	url 			= "https://github.com/abnerfs/maprestrictions"
}

public void OnPluginStart()
{
	AutoExecConfig(true, "abner_maprestrictions");
	
	g_AutoReload  	 = CreateConVar("abner_maprestrictions_autorefresh", "1", "Refresh props when player joins a team our disconnect.");
	g_Message		 = CreateConVar("abner_maprestrictions_msgs", "1", "Show message when round starts");
		
	props = new ArrayList();
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_team", PlayerJoinTeam);
	HookEvent("player_disconnect", PlayerJoinTeam);
	RegAdminCmd("refreshprops", CmdReloadProps, ADMFLAG_ROOT);
	CreateConVar("abner_maprestrictions_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
}

public Action PlayerJoinTeam(Handle ev, char[] name, bool dbroad){
	if(GetConVarInt(g_AutoReload) == 1)
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
	
	if(GetConVarInt(g_Message) != 1)
		return Plugin_Continue;
	PrintMessage();
	return Plugin_Continue;
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

stock void BuildDataPath(char[] path, char[] mapname) {
	char enginePath[100];
	EngineVersion engine = GetEngineVersion();
	switch(engine) {
		case Engine_CSGO: {
			Format(enginePath, sizeof(enginePath), "csgo");
		}
		case Engine_CSS: {
			Format(enginePath, sizeof(enginePath), "css");
		}
		default: {
			Format(enginePath, sizeof(enginePath), "other");
		}
	}
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/abner_maprestrictions/%s/%s.ini", enginePath, mapname);
}

void PrintMessage(){
	char mapname[100];
	GetCurrentMap(mapname, sizeof(mapname))
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv = new KeyValues("Messages");

	char path[PLATFORM_MAX_PATH];
	BuildDataPath(path, mapname);

	if(!FileToKeyValues(kv, path)) return;
	if(kv.JumpToKey("Messages") && kv.GotoFirstSubKey()){
		do
		{
			char Message[500];
			int MoreThan = kv.GetNum("morethan", 0);
			int LessThan = kv.GetNum("lessthan", 0);
			kv.GetString("message", Message, sizeof(Message));
			if(!StrEqual(Message, "") && PlayerCount > MoreThan && (LessThan == 0 || PlayerCount < LessThan))
			{
				CPrintToChatAll("{green}[AbNeR Map Restrictions]{default} {lightgreen}%d{default}x{lightgreen}%d {default}- {green}%s", GetTeamClientCount(2), GetTeamClientCount(3), Message);
			}
		}while(kv.GotoNextKey());	
	}
	else
	{
		SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	}
	delete kv;
}

void CreateProps(){
	char mapname[100];
	GetCurrentMap(mapname, sizeof(mapname))
	props.Clear();
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv = new KeyValues("Positions");

	char path[PLATFORM_MAX_PATH];
	BuildDataPath(path, mapname);
	
	if(!FileToKeyValues(kv, path)) return;
		
	if(kv.JumpToKey("Positions") && kv.GotoFirstSubKey())
	{
		do
		{
			char model[PLATFORM_MAX_PATH];
			kv.GetString("model", model, sizeof(model));
			int MoreThan = kv.GetNum("morethan", 0);
			int LessThan = kv.GetNum("lessthan", 0);

			
			if(kv.GotoFirstSubKey())
			{
				do
				{
					float origin[3];
					float angles[3];
					kv.GetVector("origin", origin);
					kv.GetVector("angles", angles);
					
					if(PlayerCount > MoreThan && (LessThan == 0 || PlayerCount < LessThan))
					{
						if(PrecacheModel(model,true) == 0)
							SetFailState("[AbNeR MapRestrictions] - Error precaching model '%s'", model);
						
						int Ent = CreateEntityByName("prop_physics_override"); 
					
						DispatchKeyValue(Ent, "physdamagescale", "0.0");
						DispatchKeyValue(Ent, "model", model);

						DispatchSpawn(Ent);
						SetEntityMoveType(Ent, MOVETYPE_PUSH);
						
						TeleportEntity(Ent, origin, angles, NULL_VECTOR);
						props.Push(Ent);
					}
				}while(kv.GotoNextKey());
				kv.GoBack();
			}
			else
			{
				SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
			}
		}while(kv.GotoNextKey());
	}
	else
	{
		SetFailState("[AbNeR MapRestrictions] - Corrupted %s.ini file", mapname);
	}
	delete kv;
}