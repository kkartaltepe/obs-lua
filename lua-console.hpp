// #include "ui_lua-console.h"
#include <QDialog>
#include <memory>
#include <lua.hpp>
#include <lualib.h>
#include "ui_lua-console.h"

class LuaConsole : public QDialog {
	Q_OBJECT

public:
	std::unique_ptr<Ui_LuaConsole> ui;
	LuaConsole(QWidget *parent, lua_State *L);

public slots:
	void showHideConsole();
	void runCommand();

private:
	lua_State *L;
};

//textarea setMaximumBlockCount(), appendPlainText()