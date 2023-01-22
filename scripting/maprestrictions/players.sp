enum struct PlayerState
{
	int EditingGroupNameIndex;
	int EditingGroupNameMaxPlayers;
	int SpawningEntity;
}

PlayerState g_PlayerState[MAXPLAYERS + 1];

void		Player_ClearAll()
{
	for (int i = 1; i <= MaxClients; i++)
		Player_PutIn(i);
}

void Player_PutIn(int client)
{
	InitPlayerState(g_PlayerState[client]);
}

void InitPlayerState(PlayerState state)
{
	state.EditingGroupNameIndex		 = -1;
	state.EditingGroupNameMaxPlayers = -1;
	state.SpawningEntity = -1;
}

void SetEditingGroupName(int client, int index)
{
	g_PlayerState[client].EditingGroupNameIndex = index;
}

void SetEditingGroupMaxPlayers(int client, int index)
{
	g_PlayerState[client].EditingGroupNameMaxPlayers = index;
}

void SetSpawningEntity(int client, int entity)
{
	g_PlayerState[client].SpawningEntity = entity;
}

bool Players_OnSay(int client, char message[255])
{
	if (g_PlayerState[client].EditingGroupNameIndex > -1)
	{
		RestrictionGroup r;
		GetGroup(g_PlayerState[client].EditingGroupNameIndex, r);
		PrintToChat(client, "%d", g_PlayerState[client].EditingGroupNameIndex);

		g_PlayerState[client].EditingGroupNameIndex = -1;
		r.Name										= message;
		UpdateRestrictionGroup(r);

		PrintToPlayer(client, "Name changed to %s", r.Name);
		Menus_RestrictionGroupDetail(client, r.Index);
	}
	else if (g_PlayerState[client].EditingGroupNameMaxPlayers > -1)
	{
		RestrictionGroup r;
		GetGroup(g_PlayerState[client].EditingGroupNameMaxPlayers, r);
		PrintToChat(client, "%d", g_PlayerState[client].EditingGroupNameIndex);

		int maxPlayers = StringToInt(message);
		r.MaxPlayers   = maxPlayers;
		UpdateRestrictionGroup(r);

		g_PlayerState[client].EditingGroupNameMaxPlayers = -1;

		PrintToPlayer(client, "MaxPlayers set to %d", r.MaxPlayers);
		Menus_RestrictionGroupDetail(client, r.Index);
	}

	return true;
}