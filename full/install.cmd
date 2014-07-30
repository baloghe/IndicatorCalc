@echo OFF

call passwords.cmd

:TARGETSCHEMA

echo %target_user% schema / setupDB
echo ================================= >>install.log
echo %target_user% schema >>install.log
sqlplus -S -L %target_user%/%target_pw%@%orasid% @setupDB.sql >>install.log 
if errorlevel 1 goto error
echo OK.


echo %target_user% schema / create_typeDefs
echo ================================= >>install.log
echo %target_user% schema >>install.log
sqlplus -S -L %target_user%/%target_pw%@%orasid% @create_typeDefs.sql >>install.log 
if errorlevel 1 goto error
echo OK.


echo %target_user% schema / create_package
echo ================================= >>install.log
echo %target_user% schema >>install.log
sqlplus -S -L %target_user%/%target_pw%@%orasid% @create_package.sql >>install.log 
if errorlevel 1 goto error
echo OK.

goto end


:error
echo ERROR !
echo ================================= >>install.log
type install.log

:end
@echo on
pause
