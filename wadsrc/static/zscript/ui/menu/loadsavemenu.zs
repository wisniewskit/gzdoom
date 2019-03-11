/*
** loacpp
** The load game and save game menus
**
**---------------------------------------------------------------------------
** Copyright 2001-2010 Randy Heit
** Copyright 2010-2017 Christoph Oelckers
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
**
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright
**    notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
** 3. The name of the author may not be used to endorse or promote products
**    derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
** IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
** OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
** IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
** INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
** NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
** THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**---------------------------------------------------------------------------
**
*/


struct SaveGameNode native
{
	native String SaveTitle;
	native readonly String Filename;
	native bool bOldVersion;
	native bool bMissingWads;
	native bool bNoDelete;
}

struct SavegameManager native ui
{
	native int WindowSize;
	native SaveGameNode quickSaveSlot;
	native readonly String SaveCommentString;

	native static SavegameManager GetManager();
	native void ReadSaveStrings();
	native void UnloadSaveData();

	native int RemoveSaveSlot(int index);
	native void LoadSavegame(int Selected);
	native void DoSave(int Selected, String savegamestring);
	native int ExtractSaveData(int index);
	native void ClearSaveStuff();
	native bool DrawSavePic(int x, int y, int w, int h);
	deprecated("4.0") void DrawSaveComment(Font font, int cr, int x, int y, int scalefactor) 
	{
		// Unfortunately, this was broken beyond repair so it now prints nothing.
	}
	native void SetFileInfo(int Selected);
	native int SavegameCount();
	native SaveGameNode GetSavegame(int i);
	native void InsertNewSaveNode();
	native bool RemoveNewSaveNode();

}



class LoadSaveMenu : ListMenu
{
	SavegameManager manager;
	int TopItem;
	int Selected;

	int savepicLeft;
	int savepicTop;
	int savepicWidth;
	int savepicHeight;
	int rowHeight;
	int listboxLeft;
	int listboxTop;
	int listboxWidth;
	
	int listboxRows;
	int listboxHeight;
	int listboxRight;
	int listboxBottom;

	int commentLeft;
	int commentTop;
	int commentWidth;
	int commentHeight;
	int commentRight;
	int commentBottom;
	int commentRows;

	bool mEntering;
	TextEnterMenu mInput;
	double FontScale;
	
	BrokenLines BrokenSaveComment;

	

	//=============================================================================
	//
	// 
	//
	//=============================================================================

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		manager = SavegameManager.GetManager();
		manager.ReadSaveStrings();

		savepicLeft = 10;
		savepicTop = 54*CleanYfac;
		savepicWidth = 216*screen.GetWidth() / 640;
		savepicHeight = 135*screen.GetHeight() / 400;

		FontScale = screen.GetHeight() / 480;
		rowHeight = (NewConsoleFont.GetHeight() + 1) * FontScale;
		
		listboxLeft = savepicLeft + savepicWidth + 14;
		listboxTop = savepicTop;
		listboxWidth = screen.GetWidth() - listboxLeft - 10;
		int listboxHeight1 = screen.GetHeight() - listboxTop - 10;
		listboxRows = (listboxHeight1 - 1) / rowHeight;
		listboxHeight = listboxRows * rowHeight + 1;
		listboxRight = listboxLeft + listboxWidth;
		listboxBottom = listboxTop + listboxHeight;

		commentLeft = savepicLeft;
		commentTop = savepicTop + savepicHeight + 16;
		commentWidth = savepicWidth;
		//commentHeight = (51+(screen.GetHeight()>200?10:0))*CleanYfac;
		commentHeight = listboxHeight - savepicHeight - 16;
		commentRight = commentLeft + commentWidth;
		commentBottom = commentTop + commentHeight;
		commentRows = commentHeight / rowHeight;
		
	}

	
	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void OnDestroy()
	{
		//manager.ClearSaveStuff ();
		Super.OnDestroy();
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void Drawer ()
	{
		Super.Drawer();

		SaveGameNode node;
		int i;
		int j;
		bool didSeeSelected = false;

		// Draw picture area
		if (gameaction == ga_loadgame || gameaction == ga_loadgamehidecon || gameaction == ga_savegame)
		{
			return;
		}

		Screen.DrawFrame (savepicLeft, savepicTop, savepicWidth, savepicHeight);
		if (!manager.DrawSavePic(savepicLeft, savepicTop, savepicWidth, savepicHeight))
		{
			screen.Clear (savepicLeft, savepicTop, savepicLeft+savepicWidth, savepicTop+savepicHeight, 0, 0);

			if (manager.SavegameCount() > 0)
			{
				String text = (Selected == -1 || !manager.GetSavegame(Selected).bOldVersion)? Stringtable.Localize("$MNU_NOPICTURE") : Stringtable.Localize("$MNU_DIFFVERSION");
				int textlen = SmallFont.StringWidth(text) * CleanXfac;

				screen.DrawText (SmallFont, Font.CR_GOLD, savepicLeft+(savepicWidth-textlen)/2,
					savepicTop+(savepicHeight-rowHeight)/2, text, DTA_CleanNoMove, true);
			}
		}

		// Draw comment area
		Screen.DrawFrame (commentLeft, commentTop, commentWidth, commentHeight);
		screen.Clear (commentLeft, commentTop, commentRight, commentBottom, 0, 0);

		int numlinestoprint = min(commentRows, BrokenSaveComment? BrokenSaveComment.Count() : 0);
		for(int i = 0; i < numlinestoprint; i++)
		{
			screen.DrawText(NewConsoleFont, Font.CR_ORANGE, commentLeft / FontScale, (commentTop + rowHeight * i) / FontScale, BrokenSaveComment.StringAt(i),
				DTA_VirtualWidthF, screen.GetWidth() / FontScale, DTA_VirtualHeightF, screen.GetHeight() / FontScale);
		}
		

		// Draw file area
		Screen.DrawFrame (listboxLeft, listboxTop, listboxWidth, listboxHeight);
		screen.Clear (listboxLeft, listboxTop, listboxRight, listboxBottom, 0, 0);

		if (manager.SavegameCount() == 0)
		{
			String text = Stringtable.Localize("$MNU_NOFILES");
			int textlen = SmallFont.StringWidth(text) * CleanXfac;

			screen.DrawText (NewConsoleFont, Font.CR_GOLD, (listboxLeft+(listboxWidth-textlen)/2) / FontScale, (listboxTop+(listboxHeight-rowHeight)/2) / FontScale, text, 
				DTA_VirtualWidthF, screen.GetWidth() / FontScale, DTA_VirtualHeightF, screen.GetHeight() / FontScale);
			return;
		}

		j = TopItem;
		for (i = 0; i < listboxRows && j < manager.SavegameCount(); i++)
		{
			int colr;
			node = manager.GetSavegame(j);
			if (node.bOldVersion)
			{
				colr = Font.CR_RED;
			}
			else if (node.bMissingWads)
			{
				colr = Font.CR_YELLOW;
			}
			else if (j == Selected)
			{
				colr = Font.CR_WHITE;
			}
			else
			{
				colr = Font.CR_TAN;
			}

			screen.SetClipRect(listboxLeft, listboxTop+rowHeight*i, listboxRight, listboxTop+rowHeight*(i+1));
			
			if (j == Selected)
			{
				screen.Clear (listboxLeft, listboxTop+rowHeight*i, listboxRight, listboxTop+rowHeight*(i+1), mEntering ? Color(255,255,0,0) : Color(255,0,0,255));
				didSeeSelected = true;
				if (!mEntering)
				{
					screen.DrawText (NewConsoleFont, colr, (listboxLeft+1) / FontScale, (listboxTop+rowHeight*i + FontScale) / FontScale, node.SaveTitle, 
						DTA_VirtualWidthF, screen.GetWidth() / FontScale, DTA_VirtualHeightF, screen.GetHeight() / FontScale);
				}
				else
				{
					String s = mInput.GetText() .. ConFont.GetCursor();
					int length = ConFont.StringWidth(s) * CleanXFac;
					int displacement = min(0, listboxWidth - 2 - length);
					screen.DrawText (NewConsoleFont, Font.CR_WHITE, (listboxLeft + 1 + displacement) / FontScale, (listboxTop+rowHeight*i + FontScale) / FontScale, s, 
						DTA_VirtualWidthF, screen.GetWidth() / FontScale, DTA_VirtualHeightF, screen.GetHeight() / FontScale);
				}
			}
			else
			{
				screen.DrawText (NewConsoleFont, colr, (listboxLeft+1) / FontScale, (listboxTop+rowHeight*i + FontScale) / FontScale, node.SaveTitle, 
					DTA_VirtualWidthF, screen.GetWidth() / FontScale, DTA_VirtualHeightF, screen.GetHeight() / FontScale);
			}
			screen.ClearClipRect();
			j++;
		}
	} 

	void UpdateSaveComment()
	{
		BrokenSaveComment = NewConsoleFont.BreakLines(manager.SaveCommentString, commentWidth / FontScale);
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
		case MKEY_Up:
			if (manager.SavegameCount() > 1)
			{
				if (Selected == -1) Selected = TopItem;
				else
				{
					if (--Selected < 0) Selected = manager.SavegameCount()-1;
					if (Selected < TopItem) TopItem = Selected;
					else if (Selected >= TopItem + listboxRows) TopItem = MAX(0, Selected - listboxRows + 1);
				}
				manager.UnloadSaveData ();
				manager.ExtractSaveData (Selected);
				UpdateSaveComment();
			}
			return true;

		case MKEY_Down:
			if (manager.SavegameCount() > 1)
			{
				if (Selected == -1) Selected = TopItem;
				else
				{
					if (++Selected >= manager.SavegameCount()) Selected = 0;
					if (Selected < TopItem) TopItem = Selected;
					else if (Selected >= TopItem + listboxRows) TopItem = MAX(0, Selected - listboxRows + 1);
				}
				manager.UnloadSaveData ();
				manager.ExtractSaveData (Selected);
				UpdateSaveComment();
			}
			return true;

		case MKEY_PageDown:
			if (manager.SavegameCount() > 1)
			{
				if (TopItem >= manager.SavegameCount() - listboxRows)
				{
					TopItem = 0;
					if (Selected != -1) Selected = 0;
				}
				else
				{
					TopItem = MIN(TopItem + listboxRows, manager.SavegameCount() - listboxRows);
					if (TopItem > Selected && Selected != -1) Selected = TopItem;
				}
				manager.UnloadSaveData ();
				manager.ExtractSaveData (Selected);
				UpdateSaveComment();
			}
			return true;

		case MKEY_PageUp:
			if (manager.SavegameCount() > 1)
			{
				if (TopItem == 0)
				{
					TopItem = MAX(0, manager.SavegameCount() - listboxRows);
					if (Selected != -1) Selected = TopItem;
				}
				else
				{
					TopItem = MAX(TopItem - listboxRows, 0);
					if (Selected >= TopItem + listboxRows) Selected = TopItem;
				}
				manager.UnloadSaveData ();
				manager.ExtractSaveData (Selected);
				UpdateSaveComment();
			}
			return true;

		case MKEY_Enter:
			return false;	// This event will be handled by the subclasses

		case MKEY_MBYes:
		{
			if (Selected < manager.SavegameCount())
			{
				Selected = manager.RemoveSaveSlot (Selected);
				UpdateSaveComment();
			}
			return true;
		}

		default:
			return Super.MenuEvent(mkey, fromcontroller);
		}
	}
	
	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool MouseEvent(int type, int x, int y)
	{
		if (x >= listboxLeft && x < listboxLeft + listboxWidth && 
			y >= listboxTop && y < listboxTop + listboxHeight)
		{
			int lineno = (y - listboxTop) / rowHeight;

			if (TopItem + lineno < manager.SavegameCount())
			{
				Selected = TopItem + lineno;
				manager.UnloadSaveData ();
				manager.ExtractSaveData (Selected);
				UpdateSaveComment();
				if (type == MOUSE_Release)
				{
					if (MenuEvent(MKEY_Enter, true))
					{
						return true;
					}
				}
			}
			else Selected = -1;
		}
		else Selected = -1;

		return Super.MouseEvent(type, x, y);
	}
	
	
	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_KeyDown)
		{
			if (Selected != -1 && Selected < manager.SavegameCount())
			{
				switch (ev.KeyChar)
				{
				case UIEvent.Key_F1:
					manager.SetFileInfo(Selected);
					UpdateSaveComment();
					return true;

				case UIEvent.Key_DEL:
					{
						String EndString;
						EndString = String.Format("%s%s%s%s?\n\n%s", Stringtable.Localize("$MNU_DELETESG"), TEXTCOLOR_WHITE, manager.GetSavegame(Selected).SaveTitle, TEXTCOLOR_NORMAL, Stringtable.Localize("$PRESSYN"));
						StartMessage (EndString, 0);
					}
					return true;
				}
			}
		}
		else if (ev.Type == UIEvent.Type_WheelUp)
		{
			if (TopItem > 0) TopItem--;
			return true;
		}
		else if (ev.Type == UIEvent.Type_WheelDown)
		{
			if (TopItem < manager.SavegameCount() - listboxRows) TopItem++;
			return true;
		}
		return Super.OnUIEvent(ev);
	}

	
}

class SaveMenu : LoadSaveMenu
{
	String mSaveName;
	
	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		manager.InsertNewSaveNode();
		TopItem = 0;
		Selected = manager.ExtractSaveData (-1);
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void OnDestroy()
	{
		if (manager.RemoveNewSaveNode())
		{
			Selected--;
		}
		Super.OnDestroy();
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================
	
	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (Super.MenuEvent(mkey, fromcontroller)) 
		{
			return true;
		}
		if (Selected == -1)
		{
			return false;
		}

		if (mkey == MKEY_Enter)
		{
			String SavegameString = (Selected != 0)? manager.GetSavegame(Selected).SaveTitle : "";
			mInput = TextEnterMenu.OpenTextEnter(self, ConFont, SavegameString, -1, fromcontroller);
			mInput.ActivateMenu();
			mEntering = true;
		}
		else if (mkey == MKEY_Input)
		{
			// Do not start the save here, it would cause some serious execution ordering problems.
			mEntering = false;
			mSaveName = mInput.GetText();
			mInput = null;
		}
		else if (mkey == MKEY_Abort)
		{
			mEntering = false;
			mInput = null;
		}
		return false;
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool MouseEvent(int type, int x, int y)
	{
		if (mSaveName.Length() > 0)
		{
			// Do not process events when saving is in progress to avoid update of the current index,
			// i.e. Selected member variable must remain unchanged
			return true;
		}

		return Super.MouseEvent(type, x, y);
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_KeyDown)
		{
			if (Selected != -1)
			{
				switch (ev.KeyChar)
				{
				case UIEvent.Key_DEL:
					// cannot delete 'new save game' item
					if (Selected == 0) return true;
					break;

				case 78://'N':
					Selected = TopItem = 0;
					manager.UnloadSaveData ();
					return true;
				}
			}
		}
		return Super.OnUIEvent(ev);
	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void Ticker()
	{
		if (mSaveName.Length() > 0)
		{
			manager.DoSave(Selected, mSaveName);
			mSaveName = "";
		}
	}
	
}

//=============================================================================
//
//
//
//=============================================================================

class LoadMenu : LoadSaveMenu
{
	//=============================================================================
	//
	//
	//
	//=============================================================================

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		TopItem = 0;
		Selected = manager.ExtractSaveData (-1);

	}

	//=============================================================================
	//
	//
	//
	//=============================================================================

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (Super.MenuEvent(mkey, fromcontroller)) 
		{
			return true;
		}
		if (Selected == -1 || manager.SavegameCount() == 0)
		{
			return false;
		}

		if (mkey == MKEY_Enter)
		{
			manager.LoadSavegame(Selected);
			return true;
		}
		return false;
	}
}
