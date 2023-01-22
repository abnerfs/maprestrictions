
void Menus_ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenuHandler);
	menu.SetTitle("MapRestrictions by AbNeR_CSS");
	menu.AddItem("", "Restriction groups");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
                    Menus_ShowRestrictionGroups(param1);
					// Menus_ShowRestrictionGroupMenu(param1);
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