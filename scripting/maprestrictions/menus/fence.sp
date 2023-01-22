void ShowFences(int client, int groupIndex)
{
	RestrictionGroup r;
	GetGroup(groupIndex, r);

	char sInfo[10];
	Format(sInfo, sizeof(sInfo), "%d;", groupIndex);

	Menu menu = new Menu(FencesHandler);
	menu.SetTitle("Fences %s", r.Name);
	menu.AddItem(sInfo, "Add new fence free mode");
	for (int i = 0; i < r.Restrictions.Length; i++)
	{
		Format(sInfo, sizeof(sInfo), "%d;%d", groupIndex, i);

		char sDesc[25];
		Format(sDesc, sizeof(sDesc), "Fence #%d", i);
		menu.AddItem(sInfo, sDesc);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FencesHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (param2 == MenuCancel_ExitBack)
	{
		char sInfo[10];
		menu.GetItem(0, sInfo, sizeof(sInfo));

		char buffers[2][10];
		ExplodeString(sInfo, ";", buffers, sizeof(buffers), sizeof(buffers[]));

		int groupIndex = StringToInt(buffers[0]);

		Menus_RestrictionGroupDetail(param1, groupIndex);
		return 0;
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[10];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			char buffers[2][10];
			ExplodeString(sInfo, ";", buffers, sizeof(buffers), sizeof(buffers[]));

			int groupIndex = StringToInt(buffers[0]);

			switch (param2)
			{
				case 0:
				{
					ShowSpawnMenu(param1, groupIndex);
				}
				default:
				{
					int				 fenceIndex = StringToInt(buffers[1]);

					RestrictionGroup r;
					GetGroup(groupIndex, r);

					Restriction f;
					GetRestriction(r, fenceIndex, f);
					ShowFence(param1, groupIndex, fenceIndex);
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

void ShowFence(int client, int groupIndex, int fenceIndex)
{
	RestrictionGroup r;
	GetGroup(groupIndex, r);

	Restriction f;
	GetRestriction(r, fenceIndex, f);

	Menu menu = new Menu(FenceHandler);
	char sInfo[10];
	Format(sInfo, sizeof(sInfo), "%d;%d", groupIndex, fenceIndex);

	menu.SetTitle("Fence #%d, %s", f.Index, r.Name);
	menu.AddItem(sInfo, "Add fence to right");
	menu.AddItem(sInfo, "Add fence to left");
	menu.AddItem(sInfo, "Add fence above");
	menu.AddItem(sInfo, "Remove fence");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FenceHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (param2 == MenuCancel_ExitBack)
	{
		char sInfo[10];
		menu.GetItem(1, sInfo, sizeof(sInfo));

		char buffers[2][10];
		ExplodeString(sInfo, ";", buffers, sizeof(buffers), sizeof(buffers[]));

		int groupIndex = StringToInt(buffers[0]);
		ShowFences(param1, groupIndex);
		return 0;
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[10];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			char buffers[2][10];
			ExplodeString(sInfo, ";", buffers, sizeof(buffers), sizeof(buffers[]));

			int				 groupIndex = StringToInt(buffers[0]);
			int				 fenceIndex = StringToInt(buffers[1]);

			RestrictionGroup r;
			GetGroup(groupIndex, r);

			Restriction f;
			GetRestriction(r, fenceIndex, f);

			switch (param2)
			{
				case 0:
				{
					float direction[3];
					GetAngleVectors(f.Angle, NULL_VECTOR, direction, NULL_VECTOR);
					direction[0] *= -1.0;
					direction[1] *= -1.0;

					float proppos[3];
					ScaleVector(direction, 258.0);
					AddVectors(f.Position, direction, proppos);

					Restriction newR;
					NewRestriction(newR, r.Restrictions.Length, proppos, f.Angle);

					r.Restrictions.PushArray(newR, sizeof(newR));
					UpdateRestrictionGroup(r);
					ShowFences(param1, groupIndex);
				}
				case 1:
				{
					float direction[3];
					GetAngleVectors(f.Angle, NULL_VECTOR, direction, NULL_VECTOR);

					float proppos[3];
					ScaleVector(direction, 258.0);
					AddVectors(f.Position, direction, proppos);

					Restriction newR;
					NewRestriction(newR, r.Restrictions.Length, proppos, f.Angle);

					r.Restrictions.PushArray(newR, sizeof(newR));
					UpdateRestrictionGroup(r);
					ShowFences(param1, groupIndex);
				}

				case 2:
				{
					float direction[3];
					GetAngleVectors(f.Angle, NULL_VECTOR, NULL_VECTOR, direction);

					float proppos[3];
					ScaleVector(direction, 120.0);
					AddVectors(f.Position, direction, proppos);

					Restriction newR;
					NewRestriction(newR, r.Restrictions.Length, proppos, f.Angle);

					r.Restrictions.PushArray(newR, sizeof(newR));
					UpdateRestrictionGroup(r);
					ShowFences(param1, groupIndex);
				}

				case 3:
				{
					r.Restrictions.Erase(fenceIndex);
					UpdateRestrictionGroup(r);
					ShowFences(param1, groupIndex);
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

void ShowSpawnMenu(int client, int groupIndex)
{
	RestrictionGroup r;
	GetGroup(groupIndex, r);

	float viewpos[3];
	float propang[3];
	GetPropPositionByClient(client, viewpos, propang);
	SetSpawningEntity(client, SpawnRestriction(viewpos, propang));

	char sInfo[10];
	Format(sInfo, sizeof(sInfo), "%d", groupIndex);

	Menu menu = new Menu(SpawnMenuHandler);
	menu.SetTitle("New fence %d", r.Name);
	menu.AddItem(sInfo, "Save fence");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SpawnMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char sInfo[10];
	menu.GetItem(0, sInfo, sizeof(sInfo));

	int groupIndex = StringToInt(sInfo);
	int entity	   = g_PlayerState[param1].SpawningEntity;
	if (param2 == MenuCancel_ExitBack)
	{
		if (IsValidEntity(entity) && entity != -1)
			AcceptEntityInput(entity, "kill");

		SetSpawningEntity(param1, -1);
		ShowFences(param1, groupIndex);
		return 0;
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					if (IsValidEntity(entity) && entity != -1)
					{
						float pos[3];
						float angles[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
						GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);

						RestrictionGroup r;
						GetGroup(groupIndex, r);

						Restriction f;
						NewRestriction(f, r.Restrictions.Length, pos, angles);

						r.Restrictions.PushArray(f, sizeof(f));
						UpdateRestrictionGroup(r);
						AcceptEntityInput(entity, "kill");
					}
					SetSpawningEntity(param1, -1);
					ShowFences(param1, groupIndex);
				}
			}
		}

		case MenuAction_Cancel:
		{
			if (IsValidEntity(entity) && entity != -1)
				AcceptEntityInput(g_PlayerState[param1].SpawningEntity, "kill");
			SetSpawningEntity(param1, 0);
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	return 0;
}