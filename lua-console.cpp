#include <QAction>
#include <QMainWindow>
#include <obs-frontend-api.h>
#include <obs-module.h>

#include <sstream>


#include "lua-console.hpp"
#include <lauxlib.h>

// using namespace std;

LuaConsole *lc;

LuaConsole::LuaConsole(QWidget *parent, lua_State *N)
	: QDialog(parent), ui(new Ui_LuaConsole), L(N)
{
	ui->setupUi(this);

	// Does this work with style sheets if someone wants to overload?
	QFont font("monospace");
	font.setStyleHint(QFont::Monospace);
	ui->logArea->setFont(font);
	ui->inputArea->setFont(font);

	QObject::connect(ui->inputArea, SIGNAL(returnPressed()), this, SLOT(runCommand()));
}

void LuaConsole::runCommand() {
	lua_pop(L, lua_gettop(L)); // clean stack

	auto cmd = ui->inputArea->text().toUtf8().toStdString(); // take copy or QT will blow this away
	auto ret_cmd = lua_pushfstring(L, "return %s", cmd.c_str());
	if (luaL_dostring(L, ret_cmd)) { // Try as statement call initially to match lua.c feel
		lua_pop(L, 1); // pop error
		if (luaL_dostring(L, cmd.c_str())) { // Re-try as proper function
			auto msg = lua_pushfstring(L, "error calling '%s':\n %s", cmd.c_str(), lua_tostring(L, -1));
			ui->logArea->appendPlainText(QString::fromUtf8(msg));
			lua_pop(L, lua_gettop(L)); // clean stack
			return;
		}
	}
	lua_remove(L, 1); // remove statement'ized string from lua_pushfstring

 	// Shamelessly stolen from lua.c
	int n = lua_gettop(L);
	if (n > 0) {  /* any result to be printed? */
	    luaL_checkstack(L, LUA_MINSTACK, "too many results to print");
	    lua_getglobal(L, "print");
	    lua_rotate(L, 1, 1);
	    if (lua_pcall(L, n, 0, 0) != LUA_OK) {
	    	auto msg = lua_pushfstring(L, "error calling 'print' (%s)", lua_tostring(L, -1));
	    	ui->logArea->appendPlainText(msg);
	    }
	}
	ui->inputArea->setText("");
}

void LuaConsole::showHideConsole() {
	if (isVisible()) {
		setVisible(false);
	} else {
		setVisible(true);
	}
}

extern "C" void InitLuaConsole(lua_State *L) {
	QAction *action = (QAction*)obs_frontend_add_tools_menu_qaction("Lua Console");
	QMainWindow *window = (QMainWindow*)obs_frontend_get_main_window();

	lc = new LuaConsole(window, L);

	lua_CFunction console_print = [](lua_State *LS) -> int {
		int n = lua_gettop(LS); int args = n;
		std::string formatter = "%s";
		while(args > 1){ // use string builder
			formatter += " %s";
			args--;
		}
		lua_pushstring(LS, formatter.c_str());
		lua_rotate(LS, 1, 1);
		lua_getglobal(LS, "string");
		lua_getfield(LS, -1, "format");
		lua_remove(LS, -2); // cleanup
		lua_rotate(LS, 1, 1);
		if ((int errno = lua_pcall(LS, n+1, 1, 0)) != LUA_OK) {
			auto emsg = lua_pushfstring(LS, "error calling 'string.format':\n %s", lua_tostring(LS, -1));
			lc->ui->logArea->appendPlainText(QString::fromUtf8(emsg));
			return 0;
		}
		auto msg = lua_tostring(LS, -1);
		lc->ui->logArea->appendPlainText(QString::fromUtf8(msg));
		return 0;
	};

	lua_pushcfunction(L, console_print);
	lua_setglobal(L, "print");

	auto cb = [](){
		lc->showHideConsole();
	};

	// obs_frontend_add_event_callback(OBSEvent, nullptr);
	action->connect(action, &QAction::triggered, cb);
}