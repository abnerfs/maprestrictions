#include <sourcemod>
#include <colors>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#pragma newdecls required
#define MODEL "models/props_wasteland/exterior_fence001b.mdl"

ArrayList props;

Handle g_AutoReload;
Handle g_Message;

public Plugin myinfo =
{
	name 			= "AbNeR Dust2",
	author		    = "AbNeR_CSS",
	description 	= "Area restrictions in Dust2.",
	version 		= PLUGIN_VERSION,
	url 			= "http://www.tecnohardclan.com/forum/"
}

public void OnPluginStart()
{
	LoadTranslations("abner_dust2.phrases");
	AutoExecConfig(true, "abner_dust2");
	
	g_AutoReload  	 = CreateConVar("abner_dust2_autorefresh", "1", "Refresh props when player joins a team our disconnect.");
	g_Message		 = CreateConVar("abner_dust2_msgs", "1", "Show message when round starts");
		
	props = new ArrayList();
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_team", PlayerJoinTeam);
	HookEvent("player_disconnect", PlayerJoinTeam);
	RegAdminCmd("refreshprops", CmdReloadProps, ADMFLAG_ROOT);
	CreateConVar("abner_dust2_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	
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
		
	char Text[50];
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	if(PlayerCount < 6)
		Format(Text, 100, "%t", "fundo");
	else if(PlayerCount < 10)
		Format(Text, 100, "%t", "varanda");
	
	if(!StrEqual(Text, ""))
		CPrintToChatAll("{green}[AbNeR Dust2]{default} {lightgreen}%d{default}x{lightgreen}%d {default}- {green}%s", GetTeamClientCount(2), GetTeamClientCount(3), Text);
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

void CreateProps(){
	props.Clear();
	int PlayerCount = GetTeamClientCount(3) + GetTeamClientCount(2);
	KeyValues kv = new KeyValues("Positions");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/dust2_positions.ini");
	if(!FileToKeyValues(kv, path)) SetFailState("[AbNeR Dust2] - dust2_positions.ini not found.");
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
				PrecacheModel(MODEL,true);
				int Ent = CreateEntityByName("prop_physics_override"); 
			
				DispatchKeyValue(Ent, "physdamagescale", "0.0");
				DispatchKeyValue(Ent, "model", MODEL);

				DispatchSpawn(Ent);
				SetEntityMoveType(Ent, MOVETYPE_PUSH);
				
				TeleportEntity(Ent, origin, angles, NULL_VECTOR);
				props.Push(Ent);
			}
	
		}while(kv.GotoNextKey());
	}
	else
	{
		SetFailState("[AbNeR Dust2] - Corrupted dust2_positions.ini");
	}
	delete kv;
}
