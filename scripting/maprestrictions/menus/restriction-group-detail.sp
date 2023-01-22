

void Menus_RestrictionGroupDetail(int client, int index)
{
	RestrictionGroup r;
	GetGroup(index, r);

	Menu menu = new Menu(RestrictionGroupDetail_Handler);
	menu.SetTitle("#%d %s, max players %d", index, r.Name, r.MaxPlayers);
	char sIndex[10];
	Format(sIndex, sizeof(sIndex), "%d", index);

	char sFences[255];
	Format(sFences, sizeof(sFences), "Fences %d", r.Restrictions.Length);
	menu.AddItem(sIndex, sFences);
	menu.AddItem(sIndex, "Edit name");
	menu.AddItem(sIndex, "Edit maxplayers");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RestrictionGroupDetail_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (param2 == MenuCancel_ExitBack)
	{
		Menus_ShowRestrictionGroups(param1);
		return 0;
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			char sIndex[10];
			menu.GetItem(param2, sIndex, sizeof(sIndex));

			int index = StringToInt(sIndex);

			switch (param2)
			{
				case 0:
				{
					ShowFences(param1, index);
				}
				case 1:
				{
					// edit name
					SetEditingGroupName(param1, index);
					PrintToPlayer(param1, "Type the new name for the restriction");
				}
				case 2:
				{
					// edit maxplayers
					SetEditingGroupMaxPlayers(param1, index);
					PrintToPlayer(param1, "Type the maxplayers for the restriction");
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
