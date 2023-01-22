
char	   g_MapName[255];
char	   g_ConfigPath[PLATFORM_MAX_PATH];

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

void Data_OnMapStart()
{
	GetCurrentMap(g_MapName, sizeof(g_MapName));
	BuildDataPath(g_ConfigPath, g_MapName);
	LoadRestrictionGroups();
}

KeyValues GetKVConfig()
{
	KeyValues kv = new KeyValues(g_MapName);
	if (!FileToKeyValues(kv, g_ConfigPath))
		ThrowError("Unable to load config file %s", g_ConfigPath);

	return kv;
}

void LoadRestrictions(KeyValues kv, RestrictionGroup group)
{
	if (kv.GotoFirstSubKey())
		do
		{
			float pos[3];
			kv.GetVector("pos", pos);

			float angle[3];
			kv.GetVector("angles", angle);

			Restriction r;
			NewRestriction(r, group.Restrictions.Length, pos, angle);
			AddRestrictionToGroup(group, r);
		}
		while (kv.GotoNextKey());
}

void LoadRestrictionGroups()
{
	Init_Restrictions();

	KeyValues kv = GetKVConfig();

	if (kv.JumpToKey("RestrictionGroups") && kv.GotoFirstSubKey())
	{
		do
		{
			char name[255];
			kv.GetString("name", name, sizeof(name));

			int				 maxPlayers = kv.GetNum("maxplayers", 0);

			RestrictionGroup group;
			NewRestrictionGroup(group, g_RestrictionGroups.Length, name, maxPlayers);
			AddRestrictionGroup(group);

			KeyValues restrictionsKv = new KeyValues("restrictions");
			restrictionsKv.Import(kv);
			if (restrictionsKv.JumpToKey("restrictions"))
				LoadRestrictions(restrictionsKv, group);

			delete restrictionsKv;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
}

void UpdateRestrictionGroup(RestrictionGroup r)
{
	KeyValues kv = GetKVConfig();
	if (!kv.JumpToKey("RestrictionGroups"))
		ThrowError("Invalid config file");

	char sIndex[10];
	Format(sIndex, sizeof(sIndex), "%d", r.Index);
	if (!kv.JumpToKey(sIndex))
		ThrowError("Invalid index %s", sIndex);

	kv.SetString("name", r.Name);
	kv.SetNum("maxplayers", r.MaxPlayers);
	kv.DeleteKey("restrictions");
	kv.JumpToKey("restrictions", true);

	for (int i = 0; i < r.Restrictions.Length; i++)
	{
		Restriction f;
		GetRestriction(r, i, f);

		char sfindex[10];
		Format(sfindex, sizeof(sfindex), "%d", i);

		kv.JumpToKey(sfindex, true);
		kv.SetVector("pos", f.Position);
		kv.SetVector("angles", f.Angle);
		kv.GoBack();
	}

	kv.Rewind();
	kv.ExportToFile(g_ConfigPath);

	Data_OnMapStart();
	ReloadProps();
}